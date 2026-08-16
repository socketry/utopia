# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2013-2026, by Samuel Williams.

require "sus/fixtures/protocol/http/middleware_context"
require "utopia/application"
require "utopia/controller"

describe Utopia::Controller do
	include Sus::Fixtures::Protocol::HTTP::MiddlewareContext
	
	it "freezes its configuration" do
		root = +File.expand_path(".middleware", __dir__)
		base = Class.new(Utopia::Controller::Base)
		middleware = Utopia::Controller::Middleware.new(
			Protocol::HTTP::Middleware::NotFound,
			root: root,
			base: base,
		)
		
		expect(middleware.freeze).to be_equal(middleware)
		expect(middleware).to be(:frozen?)
		expect(middleware.freeze).to be_equal(middleware)
		
		expect(root).to be(:frozen?)
		expect(base).to be(:frozen?)
	end
	
	let(:middleware) do
		root = File.expand_path(".middleware", __dir__)
		
		Utopia::Application.build do
			use Utopia::Controller, root: root
		end
	end
	
	it "should successfully call empty controller" do
		client.get "/empty/index"
		
		expect(last_response.status).to be == 404
	end
	
	it "should successfully call the controller method" do
		client.get "/controller/flat"
		
		expect(last_response.status).to be == 200
		expect(last_response.read).to be == "flat"
	end
	
	it "returns a protocol response directly" do
		root = File.expand_path(".middleware", __dir__)
		middleware = Utopia::Controller::Middleware.new(Protocol::HTTP::Middleware::NotFound, root: root)
		request = Utopia::Request["GET", "/controller/flat"]
		
		response = middleware.call(request)
		
		expect(response).to be_a(Protocol::HTTP::Response)
		expect(response.read).to be == "flat"
	end
	
	it "uses normalized URL path components" do
		root = File.expand_path(".middleware", __dir__)
		middleware = Utopia::Controller::Middleware.new(Protocol::HTTP::Middleware::NotFound, root: root)
		request = Utopia::Request["GET", "/%63ontroller/flat"]
		
		response = middleware.call(request)
		
		expect(response.status).to be == 200
		expect(response.read).to be == "flat"
	end
	
	it "rejects encoded path separators" do
		root = File.expand_path(".middleware", __dir__)
		middleware = Utopia::Controller::Middleware.new(Protocol::HTTP::Middleware::NotFound, root: root)
		request = Utopia::Request["GET", "/controller%2Fflat"]
		
		expect do
			middleware.call(request)
		end.to raise_exception(ArgumentError)
	end
	
	it "encodes rewritten paths and preserves the query" do
		root = File.expand_path(".middleware", __dir__)
		middleware = Utopia::Controller::Middleware.new(Protocol::HTTP::Middleware::NotFound, root: root)
		request = Utopia::Request["GET", "/rewrite/source?key=value"]
		
		middleware.call(request)
		
		expect(request.url.path.encoded).to be == "/rewrite/rewritten%20path"
		expect(request.url.query).to be == "key=value"
	end
	
	it "should invoke controller method from the top level" do
		client.get "/controller/hello-world"
		
		expect(last_response.status).to be == 200
		expect(last_response.read).to be == "Hello World"
	end
	
	it "should invoke the controller method with a nested path" do
		client.get "/controller/nested/hello-world"
		
		expect(last_response.status).to be == 200
		expect(last_response.read).to be == "Hello World"
	end
	
	it "shouldn't call the nested controller method" do
		client.get "/controller/nested/flat"
		
		expect(last_response.status).to be == 404
	end
	
	it "should perform ignore the request" do
		client.get "/controller/ignore"
		expect(last_response.status).to be == 404
	end
	
	it "should redirect the request" do
		client.get "/controller/redirect"
		expect(last_response.status).to be == 302
		expect(last_response.headers["location"]).to be == "bar"
	end
	
	it "encodes controller-relative redirects" do
		client.get "/controller/goto"
		expect(last_response.status).to be == 302
		expect(last_response.headers["location"]).to be == "/controller/some%20path"
	end
	
	# This was a bug, where by the controller URI_PATH was being mutated by Controller#invoke_controllers.
	it "should give the correct URI_PATH" do
		client.get "/redirect/test/bar"
		expect(last_response.status).to be == 200
		
		client.get "/redirect/test/foo"
		expect(last_response.status).to be == 200
		expect(last_response.read).to be == "/redirect"
	end
end
