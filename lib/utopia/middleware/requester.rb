
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

			class RecursiveRequestError < RuntimeError
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

