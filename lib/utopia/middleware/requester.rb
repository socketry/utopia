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

require 'set'

module Utopia
	module Middleware

		class Requester
			TTL_KEY = "utopia.requestor.ttl"
			REQUESTOR_KEY = "utopia.requestor"
			PATH_VARIABLES = Set.new
			MAXIMUM_DEPTH = 5

			class Response
				def initialize(status, headers, body)
					@status = status
					@headers = headers
					@body = body
				end

				attr :status
				attr :headers

				def body
					unless @body_string
						buffer = StringIO.new

						@body.each do |string|
							buffer.write(string)
						end

						@body_string = buffer.string
					end

					return @body_string
				end

				def [](key)
					return @headers[key]
				end

				def okay?
					@status == 200
				end
			end

			class NoRequesterError < ArgumentError
			end

			def self.[](env)
				requestor = env[REQUESTOR_KEY]
				if requestor
					return requestor
				else
					raise NoRequesterError
				end
			end

			def initialize(app, env = {})
				@app = app
				@env = env
				@env[TTL_KEY] = 0
			end

			attr :env, true

			def call(env)
				requestor = dup
				env[REQUESTOR_KEY] = requestor
				requestor.env = env.merge(@env)
				requestor.env.delete("rack.request")

				@app.call(env)
			end

			class RecursiveRequestError < StandardError
			end

			def request(env)
				env = @env.merge(env)
				env[TTL_KEY] += 1

				if env[TTL_KEY].to_i > MAXIMUM_DEPTH
					raise RecursiveRequestError, env["PATH_INFO"]
				end

				return Response.new(*@app.call(env))
			end

			def [](path, method = "GET", env = {})
				path_env = {
					"REQUEST_METHOD" => method,
					"PATH_INFO" => path.to_s
				}
				request(env.merge(path_env))
			end

			# Avoid a huge amount of junk being printed when inspecting +env+.
			def inspect
				to_s
			end
		end

	end
end

