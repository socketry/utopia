# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2016-2025, by Samuel Williams.

require "json"
require "protocol/http/body/readable"
require "sus/fixtures/protocol/http/middleware_context"
require "utopia/application"
require "utopia/content"
require "utopia/controller"
require "utopia/redirection"
require "utopia/request"

describe Utopia::Controller do
	class TestController < Utopia::Controller::Base
		# Request goes from right to left.
		prepend Utopia::Controller::Respond, Utopia::Controller::Actions
		
		responds.with("application/json") do |media_range, object|
			JSON.dump(object)
		end
		
		responds.with("text/plain") do |media_range, object|
			object.inspect
		end
		
		responds.with("application/octet-stream") do |media_range, object|
			object
		end
		
		on "fetch" do |request, path|
			succeed!({user_id: 10})
		end
		
		on "stream" do |request, path|
			succeed! @stream
		end
		
		on "explicit" do |request, path|
			respond! Utopia::Response[202, {"content-type" => "application/example"}, ["Explicit"]]
		end
		
		def self.uri_path
			Utopia::Path["/"]
		end
	end
	
	TestController.freeze
	
	let(:controller) {TestController.new}
	
	def mock_request(path, headers = {})
		request = Utopia::Request["GET", path, headers]
		
		return request, Utopia::Path[request.url.path]
	end
	
	it "should serialize response as JSON" do
		request, path = mock_request("/fetch", {"accept" => "application/json"})
		relative_path = path - controller.class.uri_path
		
		response = controller.process!(request, relative_path)
		
		expect(response.status).to be == 200
		expect(response.headers["content-type"]).to be == "application/json"
		expect(response.read).to be == '{"user_id":10}'
	end
	
	it "should serialize response as text" do
		request, path = mock_request("/fetch", {"accept" => "text/*"})
		relative_path = path - controller.class.uri_path
		
		response = controller.process!(request, relative_path)
		
		expect(response.status).to be == 200
		expect(response.headers["content-type"]).to be == "text/plain"
		expect(response.read).to be == {user_id: 10}.to_s
	end
	
	it "should select the highest quality response" do
		request, path = mock_request("/fetch", {"accept" => "text/plain;q=0.5, application/json;q=1.0"})
		relative_path = path - controller.class.uri_path
		
		response = controller.process!(request, relative_path)
		
		expect(response.headers["content-type"]).to be == "application/json"
		expect(response.read).to be == '{"user_id":10}'
	end
	
	it "preserves the requested order for equally preferred responses" do
		request, path = mock_request("/fetch", {"accept" => "text/plain, application/json"})
		relative_path = path - controller.class.uri_path
		
		response = controller.process!(request, relative_path)
		
		expect(response.headers["content-type"]).to be == "text/plain"
	end
	
	it "treats an empty accept header as accepting any response" do
		request, path = mock_request("/fetch", {"accept" => ""})
		relative_path = path - controller.class.uri_path
		
		response = controller.process!(request, relative_path)
		
		expect(response.headers["content-type"]).to be == "application/json"
	end
	
	it "preserves readable response bodies" do
		body = Protocol::HTTP::Body::Readable.new
		controller.instance_variable_set(:@stream, body)
		request, path = mock_request("/stream", {"accept" => "application/octet-stream"})
		relative_path = path - controller.class.uri_path
		
		response = controller.process!(request, relative_path)
		
		expect(response.body).to be == body
	end
	
	it "raises when no response representation is acceptable" do
		request, path = mock_request("/fetch", {"accept" => "application/xml"})
		relative_path = path - controller.class.uri_path
		
		expect do
			controller.process!(request, relative_path)
		end.to raise_exception(TypeError)
	end
	
	it "passes complete responses through without negotiation" do
		request, path = mock_request("/explicit", {"accept" => "application/xml"})
		relative_path = path - controller.class.uri_path
		
		response = controller.process!(request, relative_path)
		
		expect(response.status).to be == 202
		expect(response.headers["content-type"]).to be == "application/example"
		expect(response.read).to be == "Explicit"
	end
	
	it "falls back to the passthrough handler" do
		responder = Utopia::Controller::Responder.new
		responder.with_passthrough
		responder.freeze
		request = Utopia::Request["GET", "/", {"accept" => "application/xml"}]
		
		expect(responder.call(controller, request, "Hello World")).to be == [nil, "Hello World"]
	end
end

describe Utopia::Controller do
	include Sus::Fixtures::Protocol::HTTP::MiddlewareContext
	
	let(:middleware) do
		root = File.expand_path(".respond", __dir__)
		
		Utopia::Application.build(Protocol::HTTP::Middleware.for{|request| Utopia::Response[404, {}, []]}) do
			use Utopia::Redirection::Errors, 404 => "/fail"
			use Utopia::Controller, root: root
			use Utopia::Content, root: root
		end
	end
	
	it "should get html error page" do
		# Standard web browser header:
		client.headers["accept"] = "text/html, text/*, */*"
		
		client.get "/errors/file-not-found"
		
		expect(last_response.status).to be == 200
		expect(last_response.headers["content-type"]).to be(:include?, "text/html")
		expect(last_response.read).to be(:include?, "<h1>File Not Found</h1>")
	end
	
	it "should get html response" do
		client.headers["accept"] = "*/*"
		
		client.get "/html/hello-world"
		
		expect(last_response.status).to be == 200
		expect(last_response.headers["content-type"]).to be == "text/html"
		expect(last_response.read).to be == "<p>Hello World</p>"
	end
	
	it "should get version 1 response" do
		client.headers["accept"] = "application/json;version=1"
		
		client.get "/api/fetch"
		
		expect(last_response.status).to be == 200
		expect(last_response.headers["content-type"]).to be == "application/json"
		expect(last_response.read).to be == '{"message":"Hello World"}'
	end
	
	it "should get version 2 response" do
		client.headers["accept"] = "application/json;version=2"
		
		client.get "/api/fetch"
		
		expect(last_response.status).to be == 200
		expect(last_response.headers["content-type"]).to be == "application/json"
		expect(last_response.read).to be == '{"message":"Goodbye World"}'
	end
	
	
	it "should work even if no accept header specified" do
		client.get "/api/fetch"
		
		expect(last_response.status).to be == 200
		expect(last_response.headers["content-type"]).to be == "application/json"
		expect(last_response.read).to be == "{}"
	end
	
	it "should give record as JSON" do
		client.headers["accept"] = "application/json"
		
		client.get "/rewrite/2/show"
		
		expect(last_response.status).to be == 200
		expect(last_response.headers["content-type"]).to be == "application/json"
		expect(last_response.read).to be == '{"id":2,"foo":"bar"}'
	end
	
	it "should give error as JSON" do
		client.headers["accept"] = "application/json"
		
		client.get "/rewrite/1/show"
		
		expect(last_response.status).to be == 404
		expect(last_response.headers["content-type"]).to be == "application/json"
		expect(last_response.read).to be == '{"message":"Could not find record"}'
	end
end
