# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2013-2025, by Samuel Williams.

require "sus/fixtures/protocol/http/middleware_context"
require "utopia/application"
require "utopia/controller"

describe Utopia::Controller do
	include Sus::Fixtures::Protocol::HTTP::MiddlewareContext
	
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
	
	# This was a bug, where by the controller URI_PATH was being mutated by Controller#invoke_controllers.
	it "should give the correct URI_PATH" do
		client.get "/redirect/test/bar"
		expect(last_response.status).to be == 200
		
		client.get "/redirect/test/foo"
		expect(last_response.status).to be == 200
		expect(last_response.read).to be == "/redirect"
	end
end
