
require 'utopia/middleware'
require 'utopia/time_store'

module Utopia
	module Middleware

		class Logger
			ACCESS_LOG = "access_log"
			HEADER = [:ip, :agent, :method, :url, :status, :location, :length]

			def write_log(env, response)
				request = Rack::Request.new(env)

				record = {
					:ip => request.ip,
					:host => request.host,
					:url => request.url,
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
