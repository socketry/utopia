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

require_relative 'middleware'

require 'trenni/strings'

module Utopia
	class ExceptionHandler
		def initialize(app, location)
			@app = app

			@location = location
		end

		def fatal_error(env, exception)
			body = StringIO.new

			body.puts "<!DOCTYPE html><html><head><title>Fatal Error</title></head><body>"
			body.puts "<h1>Fatal Error</h1>"
			body.puts "<p>While requesting resource #{Trenni::Strings::to_html env['PATH_INFO']}, a fatal error occurred.</p>"
			body.puts "<blockquote><strong>#{Trenni::Strings::to_html exception.class.name}</strong>: #{Trenni::Strings::to_html exception.to_s}</blockquote>"
			body.puts "<p>There is nothing more we can do to fix the problem at this point.</p>"
			body.puts "<p>We apologize for the inconvenience.</p>"
			body.puts "</body></html>"
			body.rewind

			return [400, {"Content-Type" => "text/html"}, body]
		end

		def redirect(env, exception)
			response = @app.call(env.merge('PATH_INFO' => @location, 'REQUEST_METHOD' => 'GET'))
			
			return [500, response[1], response[2]]
		end

		def call(env)
			begin
				return @app.call(env)
			rescue Exception => exception
				# An error has occurred, log it:
				log = ::Logger.new(env['rack.errors'] || $stderr)
				
				log.error "Exception #{exception.to_s.dump}!"
				
				exception.backtrace.each do |line|
					log.error line
				end
				
				# If the error occurred while accessing the error handler, we finish with a fatal error:
				if env['PATH_INFO'] == @location
					return fatal_error(env, exception)
				else
					# If redirection fails, we also finish with a fatal error:
					begin
						return redirect(env, exception)
					rescue
						return fatal_error(env, exception)
					end
				end
			end
		end
	end
end
