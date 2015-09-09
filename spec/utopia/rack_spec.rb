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

require 'utopia/extensions/date'
require 'utopia/extensions/rack'

module Utopia::RackSpec
	describe Rack::Response do
		it "should specify not to cache content" do
			response = Rack::Response.new
			
			response.cache!(1000)
			response.do_not_cache!
			
			expect(response['Cache-Control']).to be == "no-cache, must-revalidate"
			
			expires_header = Time.parse(response['Expires'])
			expect(expires_header).to be <= Time.now
		end
		
		it "should specify to cache content" do
			response = Rack::Response.new
			
			duration = 120
			expires = Time.now + 100 # At least this far into the future
			response.cache!(duration)
			
			expect(response['Cache-Control']).to be == "public, max-age=120"
			
			expires_header = Time.parse(response['Expires'])
			expect(expires_header).to be >= expires
		end
		
		it "should set content type" do
			response = Rack::Response.new
			
			response.content_type! "text/html"
			
			expect(response['Content-Type']).to be == "text/html"
		end
	end
end
