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

require 'rack'
require 'rack/test'

require 'utopia/session'
require 'utopia/session/encrypted_cookie'

module Utopia::SessionSpec
	describe Utopia::Session do
		include Rack::Test::Methods
		
		let(:app) {Rack::Builder.parse_file('session_spec.ru').first}
		
		it "shouldn't commit session values unless required" do
			# This URL doesn't update the session:
			get "/"
			expect(last_response.header).to be == {}
			
			# This URL updates the session:
			get "/login"
			expect(last_response.header).to_not be == {}
			expect(last_response.header).to be_include 'Set-Cookie'
		end
		
		it "should set and get values correctly" do
			get "/session-set?key=foo&value=bar"
			expect(last_response.header).to be_include 'Set-Cookie'
			
			get "/session-get?key=foo"
			expect(last_response.body).to be == "bar"
		end
	end
end
