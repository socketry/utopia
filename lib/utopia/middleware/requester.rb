# Copyright (c) 2010 Samuel Williams. Released under the GNU GPLv3.
#
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
# 
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
# 
# You should have received a copy of the GNU General Public License
# along with this program.  If not, see <http://www.gnu.org/licenses/>.

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
		end

	end
end

