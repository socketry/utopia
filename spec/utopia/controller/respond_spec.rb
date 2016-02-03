#!/usr/bin/env rspec

# Copyright, 2012, by Samuel G. D. Williams. <http://www.codeotaku.com>
# 
# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:
# 
# The above copyright notice and this permission notice shall be included in
# all copies or substantial portions of the Software.
# 
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
# THE SOFTWARE.

require 'rack/test'
require 'rack/mock'
require 'json'

require 'utopia/content'
require 'utopia/controller'

module Utopia::Controller::RespondSpec
	describe Utopia::Controller::Respond::Converters do
		let(:text_html_converter) {Utopia::Controller::Respond::Converter.new("text/html", lambda {})}
		let(:text_plain_converter) {Utopia::Controller::Respond::Converter.new("text/plain", lambda {})}
		
		it "should give the correct converter when specified completely" do
			subject << text_html_converter
			subject << text_plain_converter
			
			expect(subject.for(["text/plain", "text/*", "*/*"])).to be text_plain_converter
			
			expect(subject.for(["text/html", "text/*", "*/*"])).to be text_html_converter
		end
		
		it "should match the wildcard subtype converter" do
			subject << text_html_converter
			subject << text_plain_converter
			
			expect(subject.for(["text/*", "*/*"])).to be text_html_converter
			
			expect(subject.for(["*/*"])).to be text_html_converter
		end
		
		it "should fail to match if no media types match" do
			subject << text_plain_converter
			
			expect(subject.for(["application/json"])).to be nil
		end
		
		it "should fail to match if no media types specified" do
			expect(subject.for(["text/*", "*/*"])).to be nil
		end
		
		it "should freeze converters" do
			subject << text_html_converter
			
			subject.freeze
			
			expect(text_html_converter).to be_frozen
		end
	end
	
	describe Utopia::Controller do
		class TestController < Utopia::Controller::Base
			prepend Utopia::Controller::Respond
			
			respond.with("application/json") do |content|
				JSON::dump(content)
			end
			
			respond.with("text/plain") do |content|
				content.inspect
			end
			
			on 'fetch' do |request, path|
				success! content: {user_id: 10}
			end
			
			def self.uri_path
				Utopia::Path['/']
			end
		end
		
		let(:controller) {TestController.new}
		
		def mock_request(*args)
			request = Rack::Request.new(Rack::MockRequest.env_for(*args))
			return request, Utopia::Path[request.path_info]
		end
		
		it "should serialize response as JSON" do
			request, path = mock_request("/fetch")
			relative_path = path - controller.class.uri_path
			
			request.env['HTTP_ACCEPT'] = "application/json"
			
			status, headers, body = controller.process!(request, relative_path)
			
			expect(status).to be == 200
			expect(headers['Content-Type']).to be == "application/json"
			expect(body.join).to be == '{"user_id":10}'
		end
		
		it "should serialize response as text" do
			request, path = mock_request("/fetch")
			relative_path = path - controller.class.uri_path
			
			request.env['HTTP_ACCEPT'] = "text/*"
			
			status, headers, body = controller.process!(request, relative_path)
			
			expect(status).to be == 200
			expect(headers['Content-Type']).to be == "text/plain"
			expect(body.join).to be == '{:user_id=>10}'
		end
	end
	
	describe Utopia::Controller do
		include Rack::Test::Methods
		
		let(:app) {Rack::Builder.parse_file(File.expand_path('respond_spec.ru', __dir__)).first}
		
		it "should get html error page" do
			get '/errors/file-not-found'
			
			expect(last_response.status).to be == 200
			expect(last_response.headers['Content-Type']).to be == 'text/html'
			expect(last_response.body).to be_include "<heading>File Not Found</heading>"
		end
		
		it "should get json error response" do
			get '/errors/file-not-found', nil, {'HTTP_ACCEPT' => "application/json"}
			
			expect(last_response.status).to be == 404
			expect(last_response.headers['Content-Type']).to be == 'application/json'
			expect(last_response.body).to be == '{"message":"File not found"}'
		end
	end
end
