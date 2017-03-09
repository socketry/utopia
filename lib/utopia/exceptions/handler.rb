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

module Utopia
	module Exceptions
		# Catches exceptions and performs an internal redirect.
		class Handler
			# @param location [String] Peform an internal redirect to this location when an exception is raised.
			def initialize(app, location = '/errors/exception')
				@app = app
				
				@location = location
			end
			
			def freeze
				@app.freeze
				
				@location.freeze
				
				super
			end
			
			# Generate a very simple fatal error response. This function should be unlikely to fail. Additionally, it generates a lowest common denominator response which should be suitable as a response to any kind of request. Ideally, this response is also not good or useful for any kind of higher level browser or API client, as this is not a normal error path but one that represents broken behaviour.
			def fatal_error(env, exception)
				body = StringIO.new
				
				write_exception_to_stream(body, env, exception)
				body.rewind
				
				return [500, {HTTP::CONTENT_TYPE => "text/plain"}, body]
			end
			
			def log_exception(env, exception)
				# An error has occurred, log it:
				output = env['rack.errors'] || $stderr
				write_exception_to_stream(output, env, exception, true)
			end
			
			def call(env)
				begin
					return @app.call(env)
				rescue Exception => exception
					log_exception(env, exception)
					
					# If the error occurred while accessing the error handler, we finish with a fatal error:
					if env[Rack::PATH_INFO] == @location
						return fatal_error(env, exception)
					else
						begin
							# We do an internal redirection to the error location:
							error_request = env.merge(Rack::PATH_INFO => @location, Rack::REQUEST_METHOD => Rack::GET)
							error_response = @app.call(error_request)
							
							return [500, error_response[1], error_response[2]]
						rescue Exception
							# If redirection fails, we also finish with a fatal error:
							return fatal_error(env, exception)
						end
					end
				end
			end
			
			private def write_exception_to_stream(stream, env, exception, include_backtrace = false)
				buffer = []
				
				buffer << "While requesting resource #{env[Rack::PATH_INFO].inspect}, a fatal error occurred:"
				
				while exception != nil
					buffer << "\t#{exception.class.name}: #{exception.to_s}"
					
					if include_backtrace
						exception.backtrace.each do |line|
							buffer << "\t\t#{line}"
						end
					end
					
					exception = exception.cause
				end
				
				# We do this in one go so that lines don't get mixed up.
				stream.puts buffer.join("\n")
			end
		end
	end
end
