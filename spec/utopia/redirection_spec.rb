# frozen_string_literal: true

# Copyright, 2016, by Samuel G. D. Williams. <http://www.codeotaku.com>
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

require_relative 'rack_helper'
require 'utopia/redirection'

RSpec.describe Utopia::Redirection do
	include_context "rack app", "redirection_spec.ru"
	
	it "should redirect directory to index" do
		get "/welcome/"
		
		expect(last_response.status).to be == 307
		expect(last_response.headers['location']).to be == '/welcome/index'
		expect(last_response.headers['cache-control']).to include("max-age=86400")
	end
	
	it "should be permanently moved" do
		get "/a"
		
		expect(last_response.status).to be == 301
		expect(last_response.headers['location']).to be == '/b'
		expect(last_response.headers['cache-control']).to include("max-age=86400")
	end
	
	it "should be permanently moved" do
		get "/"
		
		expect(last_response.status).to be == 301
		expect(last_response.headers['location']).to be == '/welcome/index'
		expect(last_response.headers['cache-control']).to include("max-age=86400")
	end
	
	it "should redirect on 404" do
		get "/foo"
		
		expect(last_response.status).to be == 404
		expect(last_response.body).to be == "File not found :("
	end
	
	it "should blow up if internal error redirect also fails" do
		expect{get "/teapot"}.to raise_error Utopia::Redirection::RequestFailure
	end
	
	it "should redirect deep url to top" do
		get "/hierarchy/a/b/c/d/e"
		
		expect(last_response.status).to be == 301
		expect(last_response.headers['location']).to be == '/hierarchy'
	end
	
	it "should get a weird status" do
		get "/weird"
		
		expect(last_response.status).to be == 333
		expect(last_response.headers['location']).to be == '/status'
	end
end
