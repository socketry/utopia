# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2009-2022, by Samuel Williams.

require_relative 'middleware'

module Utopia
	# A middleware which assists with redirecting from one path to another.
	module Redirection
		# An error handler fails to redirect to a valid page.
		class RequestFailure < StandardError
			def initialize(resource_path, resource_status, error_path, error_status)
				@resource_path = resource_path
				@resource_status = resource_status

				@error_path = error_path
				@error_status = error_status
				
				super "Requested resource #{@resource_path} resulted in a #{@resource_status} error. Requested error handler #{@error_path} resulted in a #{@error_status} error."
			end
		end
		
		# A middleware which performs internal redirects based on error status codes.
		class Errors
			# @param codes [Hash<Integer,String>] The redirection path for a given error code.
			def initialize(app, codes = {})
				@app = app
				@codes = codes
			end
			
			def freeze
				return self if frozen?
				
				@codes.freeze
				
				super
			end
			
			def unhandled_error?(response)
				response[0] >= 400 && response[1].empty?
			end
			
			def call(env)
				response = @app.call(env)
				
				if unhandled_error?(response) && location = @codes[response[0]]
					error_request = env.merge(Rack::PATH_INFO => location, Rack::REQUEST_METHOD => Rack::GET)
					error_response = @app.call(error_request)

					if error_response[0] >= 400
						raise RequestFailure.new(env[Rack::PATH_INFO], response[0], location, error_response[0])
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
		
		# We cache 301 redirects for 24 hours.
		DEFAULT_MAX_AGE = 3600*24
		
		# A basic client-side redirect.
		class ClientRedirect
			def initialize(app, status: 307, max_age: DEFAULT_MAX_AGE)
				@app = app
				@status = status
				@max_age = max_age
			end
			
			def freeze
				return self if frozen?
				
				@status.freeze
				@max_age.freeze
				
				super
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
		
		# Redirect urls that end with a `/`, e.g. directories.
		class DirectoryIndex < ClientRedirect
			def initialize(app, index: 'index')
				@app = app
				@index = index
				
				super(app)
			end
			
			def [] path
				if path.end_with?('/')
					return redirect(path + @index)
				end
			end
		end
		
		# Rewrite requests that match the given pattern to a single destination.
		class Rewrite < ClientRedirect
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
		
		# Rewrite requests that match the given pattern to a new prefix.
		class Moved < ClientRedirect
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
