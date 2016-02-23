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

require_relative '../rack_helper'
require 'utopia/exceptions'

RSpec.describe Utopia::Exceptions::Handler do
	include_context "rack app", File.expand_path("handler_spec.ru", __dir__)
	
	it "should successfully call the controller method" do
		# This request will raise an exception, and then redirect to the /exception url which will fail again, and cause a fatal error.
		get "/blow?fatal=true"
		
		expect(last_response.status).to be == 500
		expect(last_response.headers['Content-Type']).to be == 'text/plain'
		expect(last_response.body).to be_include 'fatal error'
	end
	
	it "should fail with a 500 error" do
		get "/blow"
		
		expect(last_response.status).to be == 500
		expect(last_response.body).to be_include 'Error Will Robertson'
	end
end
