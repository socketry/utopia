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

require 'utopia/middleware'
require 'utopia/extensions/string'

module Utopia
	module Middleware
		class ExceptionHandler
			def initialize(app, location)
				@app = app

				@location = location
			end

			def fatal_error(env, ex)
				body = StringIO.new

				body.puts "<!DOCTYPE html><html><head><title>Fatal Error</title></head><body>"
				body.puts "<h1>Fatal Error</h1>"
				body.puts "<p>While requesting resource #{env['PATH_INFO'].to_html}, a fatal error occurred.</p>"
				body.puts "<blockquote><strong>#{ex.class.name.to_html}</strong>: #{ex.to_s.to_html}</blockquote>"
				body.puts "<p>There is nothing more we can do to fix the problem at this point.</p>"
				body.puts "<p>We apologize for the inconvenience.</p>"
				body.puts "</body></html>"
				body.rewind

				return [400, {"Content-Type" => "text/html"}, body]
			end

			def redirect(env, ex)
				return @app.call(env.merge('PATH_INFO' => @location, 'REQUEST_METHOD' => 'GET'))
			end

			def call(env)
				begin
					return @app.call(env)
				rescue Exception => ex
					log = ::Logger.new(env['rack.errors'])
					
					log.error "Exception #{ex.to_s.dump}!"
					
					ex.backtrace.each do |bt|
						log.error bt
					end
					
					if env['PATH_INFO'] == @location
						return fatal_error(env, ex)
					else

						# If redirection fails
						begin
							return redirect(env, ex)
						rescue
							return fatal_error(env, ex)
						end

					end
				end
			end
		end
	end
end
