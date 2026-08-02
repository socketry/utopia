# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2013-2025, by Samuel Williams.

require "utopia/controller"
require_relative "../protocol_application"

describe Utopia::Controller do
	include ProtocolApplication
	
	let(:app) do
		root = File.expand_path(".middleware", __dir__)
		
		Utopia::Application.build do
			use Utopia::Controller, root: root
		end
	end
	
	it "should successfully call empty controller" do
		get "/empty/index"
		
		expect(last_response.status).to be == 404
	end
	
	it "should successfully call the controller method" do
		get "/controller/flat"
		
		expect(last_response.status).to be == 200
		expect(body).to be == "flat"
	end
	
	it "should invoke controller method from the top level" do
		get "/controller/hello-world"
		
		expect(last_response.status).to be == 200
		expect(body).to be == "Hello World"
	end
	
	it "should invoke the controller method with a nested path" do
		get "/controller/nested/hello-world"
		
		expect(last_response.status).to be == 200
		expect(body).to be == "Hello World"
	end
	
	it "shouldn't call the nested controller method" do
		get "/controller/nested/flat"
		
		expect(last_response.status).to be == 404
	end
	
	it "should perform ignore the request" do
		get "/controller/ignore"
		expect(last_response.status).to be == 404
	end
	
	it "should redirect the request" do
		get "/controller/redirect"
		expect(last_response.status).to be == 302
		expect(last_response.headers["location"]).to be == "bar"
	end
	
	# This was a bug, where by the controller URI_PATH was being mutated by Controller#invoke_controllers.
	it "should give the correct URI_PATH" do
		get "/redirect/test/bar"
		expect(last_response.status).to be == 200
		
		get "/redirect/test/foo"
		expect(last_response.status).to be == 200
		expect(body).to be == "/redirect"
	end
end
