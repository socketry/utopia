#!/usr/bin/env rspec
# Copyright, 2014, by Samuel G. D. Williams. <http://www.codeotaku.com>
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

require 'utopia/static'

module Utopia::StaticSpec
	describe Utopia::Static do
		include Rack::Test::Methods
		
		let(:app) {Rack::Builder.parse_file(File.expand_path('../static_spec.ru', __FILE__)).first}
		
		it "should give the correct mime type" do
			get "/test.txt"
			
			expect(last_response.header['Content-Type']).to be == 'text/plain'
		end
		
		it "should return partial content" do
			get "/test.txt", {}, 'HTTP_RANGE' => 'bytes=1-4'
			
			expect(last_response.status).to be == 206 
			expect(last_response.content_length).to be == 4
			expect(last_response.body).to be == "ello"
		end
	end
end
