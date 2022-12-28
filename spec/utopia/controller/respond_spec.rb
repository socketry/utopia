#!/usr/bin/env rspec
# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2016-2022, by Samuel Williams.

require 'rack/test'
require 'rack/mock'
require 'json'

require 'utopia/content'
require 'utopia/controller'
require 'utopia/redirection'

module Utopia::Controller::RespondSpec
	describe Utopia::Controller do
		class TestController < Utopia::Controller::Base
			# Request goes from right to left.
			prepend Utopia::Controller::Respond, Utopia::Controller::Actions
			
			responds.with("application/json") do |media_range, object|
				succeed! content: JSON.dump(object), type: 'application/json'
			end
			
			responds.with("text/plain") do |media_range, object|
				succeed! content: object.inspect,	type: 'text/plain'
			end
			
			on 'fetch' do |request, path|
				succeed! content: {user_id: 10}
			end
			
			def self.uri_path
				Utopia::Path['/']
			end
		end
		
		let(:controller) {TestController.new}
		
		def mock_request(*arguments)
			request = Rack::Request.new(Rack::MockRequest.env_for(*arguments))
			return request, Utopia::Path[request.path_info]
		end
		
		it "should serialize response as JSON" do
			request, path = mock_request("/fetch")
			relative_path = path - controller.class.uri_path
			
			request.env['HTTP_ACCEPT'] = "application/json"
			
			status, headers, body = controller.process!(request, relative_path)
			
			expect(status).to be == 200
			expect(headers['content-type']).to be == "application/json"
			expect(body.join).to be == '{"user_id":10}'
		end
		
		it "should serialize response as text" do
			request, path = mock_request("/fetch")
			relative_path = path - controller.class.uri_path
			
			request.env['HTTP_ACCEPT'] = "text/*"
			
			status, headers, body = controller.process!(request, relative_path)
			
			expect(status).to be == 200
			expect(headers['content-type']).to be == "text/plain"
			expect(body.join).to be == '{:user_id=>10}'
		end
	end
	
	describe Utopia::Controller do
		include Rack::Test::Methods
		
		let(:app) {Rack::Builder.parse_file(File.expand_path('respond_spec.ru', __dir__))}
		
		it "should get html error page" do
			# Standard web browser header:
			header 'accept', 'text/html, text/*, */*'
			
			get '/errors/file-not-found'
			
			expect(last_response.status).to be == 200
			expect(last_response.headers['content-type']).to include('text/html')
			expect(last_response.body).to be_include "<h1>File Not Found</h1>"
		end
		
		it 'should get html response' do
			header 'accept', '*/*'
			
			get '/html/hello-world'
			
			expect(last_response.status).to be == 200
			expect(last_response.headers['content-type']).to be == 'text/html'
			expect(last_response.body).to be == '<p>Hello World</p>'
		end
		
		it "should get version 1 response" do
			header 'accept', 'application/json;version=1'
			
			get '/api/fetch'
			
			expect(last_response.status).to be == 200
			expect(last_response.headers['content-type']).to be == 'application/json'
			expect(last_response.body).to be == '{"message":"Hello World"}'
		end
		
		it "should get version 2 response" do
			header 'accept', 'application/json;version=2'
			
			get '/api/fetch'
			
			expect(last_response.status).to be == 200
			expect(last_response.headers['content-type']).to be == 'application/json'
			expect(last_response.body).to be == '{"message":"Goodbye World"}'
		end
		
		
		it "should work even if no accept header specified" do
			get '/api/fetch'
			
			expect(last_response.status).to be == 200
			expect(last_response.headers['content-type']).to be == 'application/json'
			expect(last_response.body).to be == '{}'
		end
		
		it "should give record as JSON" do
			header 'accept', 'application/json'
			
			get '/rewrite/2/show'
			
			expect(last_response.status).to be == 200
			expect(last_response.headers['content-type']).to be == 'application/json'
			expect(last_response.body).to be == '{"id":2,"foo":"bar"}'
		end
		
		it "should give error as JSON" do
			header 'accept', 'application/json'
			
			get '/rewrite/1/show'
			
			expect(last_response.status).to be == 404
			expect(last_response.headers['content-type']).to be == 'application/json'
			expect(last_response.body).to be == '{"message":"Could not find record"}'
		end
	end
end
