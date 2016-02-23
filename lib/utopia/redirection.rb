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

require_relative 'middleware'

module Utopia
	module Redirection
		class RequestFailure < StandardError
			def initialize(resource_path, resource_status, error_path, error_status)
				@resource_path = resource_path
				@resource_status = resource_status

				@error_path = error_path
				@error_status = error_status
				
				super "Requested resource #{@resource_path} resulted in a #{@resource_status} error. Requested error handler #{@error_path} resulted in a #{@error_status} error."
			end
		end
		
		class Errors
			# Maps an error code to a given string
			def initialize(app, codes = {})
				@codes = codes
				@app = app
			end
			
			def call(env)
				response = @app.call(env)
				
				if response[0] >= 400 and uri = @codes[response[0]]
					error_request = env.merge(Rack::PATH_INFO => uri, Rack::REQUEST_METHOD => Rack::GET)
					error_response = @app.call(error_request)

					if error_response[0] >= 400
						raise RequestFailure.new(env[Rack::PATH_INFO], response[0], uri, error_response[0])
					else
						# Feed the error code back with the error document:
						error_response[0] = response[0]
						return error_response
					end
				else
					return response
				end
			end
		end
		
		class FileNotFound < Errors
			def initialize(uri = '/errors/file-not-found')
				super(404 => uri)
			end
		end
		
		# We cache 301 redirects for 24 hours.
		DEFAULT_MAX_AGE = 3600*24
		
		class Redirection
			def initialize(app, status: 307, max_age: DEFAULT_MAX_AGE)
				@app = app
				@status = status
				@max_age = max_age
			end
			
			attr :status
			attr :max_age
			
			def cache_control
				# http://jacquesmattheij.com/301-redirects-a-dangerous-one-way-street
				"max-age=#{self.max_age}"
			end
			
			def headers(location)
				{HTTP::LOCATION => location, HTTP::CACHE_CONTROL => self.cache_control}
			end
			
			def redirect(location)
				return [self.status, self.headers(location), []]
			end
			
			def [] path
				false
			end
			
			def call(env)
				path = env[Rack::PATH_INFO]
				
				if redirection = self[path]
					return redirection
				end
				
				return @app.call(env)
			end
		end
		
		class DirectoryIndex < Redirection
			def initialize(app, index = 'index')
				@app = app
				@index = 'index'
				
				super(app)
			end
			
			def [] path
				if path.end_with?('/')
					return redirect(path + @index)
				end
			end
		end
		
		class Rewrite < Redirection
			def initialize(app, patterns, status: 301)
				@patterns = patterns
				
				super(app, status: status)
			end
			
			def [] path
				if location = @patterns[path]
					return redirect(location)
				end
			end
		end
		
		class Moved < Redirection
			def initialize(app, pattern, prefix, status: 301, flatten: false)
				@app = app
				
				@pattern = pattern
				@prefix = prefix
				@flatten = flatten
				
				super(app, status: status)
			end
			
			def [] path
				if path.start_with?(@pattern)
					if @flatten
						return redirect(@prefix)
					else
						return redirect(path.sub(@pattern, @prefix))
					end
				end
			end
		end
	end
end
