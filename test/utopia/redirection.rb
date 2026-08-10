# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2016-2026, by Samuel Williams.

require "sus/fixtures/protocol/http/middleware_context"
require "utopia/application"
require "utopia/redirection"

describe Utopia::Redirection do
	include Sus::Fixtures::Protocol::HTTP::MiddlewareContext
	
	def tracked_body(name, events)
		body = Protocol::HTTP::Body::Buffered.wrap([name.to_s])
		
		body.define_singleton_method(:close) do |error = nil|
			events << [name, error]
			super(error)
		end
		
		return body
	end
	
	let(:middleware) do
		Utopia::Application.build(Protocol::HTTP::Middleware.for{|request|
			case request.path_info
			when "/error"
				Utopia::Response.text("File not found :(", 200)
			when "/teapot"
				Utopia::Response[418, {}, ["I'm a teapot!"]]
			else
				Utopia::Response[404, {}, []]
			end
		}) do
			use Utopia::Redirection do |redirects|
				redirects.rewrite "/" => "/welcome/index"
				redirects.directory_index
				redirects.moved "/a", "/b"
				redirects.moved "/hierarchy/", "/hierarchy", flatten: true
				redirects.moved "/weird", "/status", status: 333
			end
			use Utopia::Redirection::Errors, 404 => "/error", 418 => "/teapot"
		end
	end
	
	it "should redirect directory to index" do
		client.get "/welcome/"
		
		expect(last_response.status).to be == 307
		expect(last_response.headers["location"]).to be == "/welcome/index"
		expect(last_response.headers["cache-control"]).to be(:include?, "max-age=86400")
	end
	
	it "should not allow open redirect via protocol-relative URL" do
		client.get "//evil.com/"
		
		# Must not redirect to //evil.com/index (external host)
		if last_response.status == 307
			expect(last_response.headers["location"]).not.to be(:start_with?, "//")
		end
	end
	
	it "should be permanently moved" do
		client.get "/a"
		
		expect(last_response.status).to be == 301
		expect(last_response.headers["location"]).to be == "/b"
		expect(last_response.headers["cache-control"]).to be(:include?, "max-age=86400")
	end
	
	it "should be permanently moved" do
		client.get "/"
		
		expect(last_response.status).to be == 301
		expect(last_response.headers["location"]).to be == "/welcome/index"
		expect(last_response.headers["cache-control"]).to be(:include?, "max-age=86400")
	end
	
	it "should redirect on 404" do
		client.get "/foo"
		
		expect(last_response.status).to be == 404
		expect(last_response.read).to be == "File not found :("
	end
	
	it "bypasses request redirections for internal error documents" do
		application = Utopia::Application.build(Protocol::HTTP::Middleware.for do |request|
			if request.path_info == "/error"
				Utopia::Response.text("Internal error document")
			else
				Utopia::Response[404, {}, []]
			end
		end) do
			use Utopia::Redirection do |redirects|
				redirects.rewrite "/error" => "/redirected"
			end
			use Utopia::Redirection::Errors, 404 => "/error"
		end
		
		response = application.call(Protocol::HTTP::Request["GET", "/missing"])
		
		expect(response.status).to be == 404
		expect(response.headers["location"]).to be == nil
		expect(response.read).to be == "Internal error document"
	end
	
	it "closes the response replaced by an error document" do
		events = []
		application = Utopia::Application.build(Protocol::HTTP::Middleware.for do |request|
			if request.path_info == "/error"
				Utopia::Response[200, {}, tracked_body(:error, events)]
			else
				Utopia::Response[404, {}, tracked_body(:original, events)]
			end
		end) do
			use Utopia::Redirection::Errors, 404 => "/error"
		end
		
		response = application.call(Protocol::HTTP::Request["GET", "/missing"])
		
		expect(response.status).to be == 404
		expect(events).to be == [[:original, nil]]
		expect(response.read).to be == "error"
	end
	
	it "should blow up if internal error redirect also fails" do
		expect{client.get "/teapot"}.to raise_exception Utopia::Redirection::RequestFailure
	end
	
	it "closes both responses when the error document fails" do
		events = []
		application = Utopia::Application.build(Protocol::HTTP::Middleware.for do |request|
			if request.path_info == "/error"
				Utopia::Response[500, {}, tracked_body(:error, events)]
			else
				Utopia::Response[404, {}, tracked_body(:original, events)]
			end
		end) do
			use Utopia::Redirection::Errors, 404 => "/error"
		end
		
		expect do
			application.call(Protocol::HTTP::Request["GET", "/missing"])
		end.to raise_exception(Utopia::Redirection::RequestFailure)
		
		expect(events.size).to be == 2
		expect(events[0]).to be == [:original, nil]
		expect(events[1][0]).to be == :error
		expect(events[1][1]).to be_a(Utopia::Redirection::RequestFailure)
	end
	
	it "should redirect deep url to top" do
		client.get "/hierarchy/a/b/c/d/e"
		
		expect(last_response.status).to be == 301
		expect(last_response.headers["location"]).to be == "/hierarchy"
	end
	
	it "should get a weird status" do
		client.get "/weird"
		
		expect(last_response.status).to be == 333
		expect(last_response.headers["location"]).to be == "/status"
	end
	
	it "applies request rules in declaration order" do
		application = Utopia::Application.build do
			use Utopia::Redirection do |redirects|
				redirects.rewrite "/files/" => "/exact"
				redirects.directory_index "index"
			end
		end
		
		response = application.call(Protocol::HTTP::Request["GET", "/files/"])
		
		expect(response.headers["location"]).to be == "/exact"
	end
end
