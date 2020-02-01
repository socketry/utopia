#!/usr/bin/env rspec
# frozen_string_literal: true

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

require 'rack/mock'
require 'rack/test'
require 'utopia/controller'

module Utopia::Controller::MiddlewareSpec
	describe Utopia::Controller do
		include Rack::Test::Methods
		
		let(:app) {Rack::Builder.parse_file(File.expand_path('../middleware_spec.ru', __FILE__)).first}
		
		it "should successfully call empty controller" do
			get "/empty/index"
			
			expect(last_response.status).to be == 404
		end
		
		it "should successfully call the controller method" do
			get "/controller/flat"
			
			expect(last_response.status).to be == 200
			expect(last_response.body).to be == 'flat'
		end
		
		it "should invoke controller method from the top level" do
			get "/controller/hello-world"
			
			expect(last_response.status).to be == 200
			expect(last_response.body).to be == 'Hello World'
		end

		it "should invoke the controller method with a nested path" do
			get "/controller/nested/hello-world"
			
			expect(last_response.status).to be == 200
			expect(last_response.body).to be == 'Hello World'
		end
		
		it "shouldn't call the nested controller method" do
			get "/controller/nested/flat"
			
			expect(last_response.status).to be == 404
		end
		
		it "should perform ignore the request" do
			get '/controller/ignore'
			expect(last_response.status).to be == 404
		end
		
		it "should redirect the request" do
			get '/controller/redirect'
			expect(last_response.status).to be == 302
			expect(last_response.headers['Location']).to be == 'bar'
		end
		
		# This was a bug, where by the controller URI_PATH was being mutated by Controller#invoke_controllers.
		it "should give the correct URI_PATH" do
			get '/redirect/test/bar'
			expect(last_response.status).to be == 200
			
			get '/redirect/test/foo'
			expect(last_response.status).to be == 200
			expect(last_response.body).to be == '/redirect'
		end
	end
end
