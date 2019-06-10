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

require_relative 'middleware'

module Utopia
	# A faster implementation of Rack::ContentLength which doesn't rewrite body, but does expect it to either be an Array or an object that responds to #bytesize.
	class ContentLength
		def initialize(app)
			@app = app
		end
		
		def content_length_of(body)
			if body.respond_to?(:map)
				return body.map(&:bytesize).reduce(0, :+)
			end
		end
		
		def call(env)
			response = @app.call(env)
			
			unless response[2]&.empty? or response[1].include?(Rack::CONTENT_LENGTH)
				if content_length = self.content_length_of(response[2])
					response[1][Rack::CONTENT_LENGTH] = content_length
				end
			end
			
			return response
		end
	end
end
