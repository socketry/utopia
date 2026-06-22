# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2016-2025, by Samuel Williams.

require "json"
require "protocol/http/request"

require "utopia/content"
require "utopia/controller"
require "utopia/redirection"
require "utopia/request"
require_relative "../protocol_application"

describe Utopia::Controller do
	class TestController < Utopia::Controller::Base
		# Request goes from right to left.
		prepend Utopia::Controller::Respond, Utopia::Controller::Actions
		
		responds.with("application/json") do |media_range, object|
			succeed! content: JSON.dump(object), type: "application/json"
		end
		
		responds.with("text/plain") do |media_range, object|
			succeed! content: object.inspect,	type: "text/plain"
		end
		
		on "fetch" do |request, path|
			succeed! content: {user_id: 10}
		end
		
		def self.uri_path
			Utopia::Path["/"]
		end
	end
	
	let(:controller) {TestController.new}
	
	def mock_request(path, headers = {})
		request = Utopia::Request.new(Protocol::HTTP::Request["GET", path, headers])
		return request, Utopia::Path[request.path_info]
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
end

describe Utopia::Controller do
	include ProtocolApplication
	
	let(:app) do
		root = File.expand_path(".respond", __dir__)
		
		Utopia::Application.build(lambda{|request| Utopia::Response[404, {}, []]}) do
			use Utopia::Redirection::Errors, 404 => "/fail"
			use Utopia::Controller, root: root
			use Utopia::Content, root: root
		end
	end
	
	it "should get html error page" do
		# Standard web browser header:
		header "accept", "text/html, text/*, */*"
		
		get "/errors/file-not-found"
		
		expect(last_response.status).to be == 200
		expect(last_response.headers["content-type"]).to be(:include?, "text/html")
		expect(body).to be(:include?, "<h1>File Not Found</h1>")
	end
	
	it "should get html response" do
		header "accept", "*/*"
		
		get "/html/hello-world"
		
		expect(last_response.status).to be == 200
		expect(last_response.headers["content-type"]).to be == "text/html"
		expect(body).to be == "<p>Hello World</p>"
	end
	
	it "should get version 1 response" do
		header "accept", "application/json;version=1"
		
		get "/api/fetch"
		
		expect(last_response.status).to be == 200
		expect(last_response.headers["content-type"]).to be == "application/json"
		expect(body).to be == '{"message":"Hello World"}'
	end
	
	it "should get version 2 response" do
		header "accept", "application/json;version=2"
		
		get "/api/fetch"
		
		expect(last_response.status).to be == 200
		expect(last_response.headers["content-type"]).to be == "application/json"
		expect(body).to be == '{"message":"Goodbye World"}'
	end
	
	
	it "should work even if no accept header specified" do
		get "/api/fetch"
		
		expect(last_response.status).to be == 200
		expect(last_response.headers["content-type"]).to be == "application/json"
		expect(body).to be == "{}"
	end
	
	it "should give record as JSON" do
		header "accept", "application/json"
		
		get "/rewrite/2/show"
		
		expect(last_response.status).to be == 200
		expect(last_response.headers["content-type"]).to be == "application/json"
		expect(body).to be == '{"id":2,"foo":"bar"}'
	end
	
	it "should give error as JSON" do
		header "accept", "application/json"
		
		get "/rewrite/1/show"
		
		expect(last_response.status).to be == 404
		expect(last_response.headers["content-type"]).to be == "application/json"
		expect(body).to be == '{"message":"Could not find record"}'
	end
end
