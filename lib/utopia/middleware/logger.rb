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

require 'utopia/middleware'
require 'utopia/time_store'

module Utopia
	module Middleware

		class Logger
			ACCESS_LOG = "access_log"
			HEADER = [:ip, :agent, :method, :url, :status, :location, :referer, :length]

			def write_log(env, response)
				request = Rack::Request.new(env)

				record = {
					:ip => request.ip,
					:host => request.host,
					:url => request.url,
					:referer => request.referer,
					:agent => env['HTTP_USER_AGENT'],
					:status => response[0],
					:method => request.request_method,
					:user => env['REMOTE_USER'],
					:version => env['HTTP_VERSION']
				}

				if response[1].key? "Location"
					record[:location] = response[1]["Location"]
				end
				
				if response[1].key? "Content-Length"
					record[:length] = response[1]["Content-Length"]
				end

				@log << record
				
				if UTOPIA_ENV != :production
					$stderr.puts ">> #{record[:method]} #{record[:url]} -> #{response[0]}"
				end
			end

			def initialize(app, options = {})
				@app = app
				
				@log = options[:log] || TimeStore.new(options[:path] || ACCESS_LOG, options[:header] || HEADER)
			end

			def call(env)
				response = @app.call(env)

				Thread.new do
					write_log(env, response)
				end

				return response
			end
		end
	end
end
