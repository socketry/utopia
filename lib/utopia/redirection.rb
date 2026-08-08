# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2009-2026, by Samuel Williams.

require_relative "middleware"
require_relative "request"
require_relative "response"

module Utopia
	# A middleware which assists with redirecting from one path to another.
	module Redirection
		# An error handler fails to redirect to a valid page.
		class RequestFailure < StandardError
			# Describe a failed attempt to render an error document.
			# @parameter resource_path [Object] The resource path.
			# @parameter resource_status [Object] The resource status.
			# @parameter error_path [Object] The error path.
			# @parameter error_status [Object] The error status.
			def initialize(resource_path, resource_status, error_path, error_status)
				@resource_path = resource_path
				@resource_status = resource_status
				
				@error_path = error_path
				@error_status = error_status
				
				super "Requested resource #{@resource_path} resulted in a #{@resource_status} error. Requested error handler #{@error_path} resulted in a #{@error_status} error."
			end
		end
		
		# A middleware which performs internal redirects based on error status codes.
		class Errors < Protocol::HTTP::Middleware
			# @param codes [Hash<Integer,String>] The redirection path for a given error code.
			def initialize(app, codes = {})
				super(app)
				
				@codes = codes
			end
			
			# Freeze this object and its internal state.
			# @returns [self] This object.
			def freeze
				return self if frozen?
				
				@codes.freeze
				
				super
			end
			
			# Check whether the response status requires error handling.
			# @parameter response [Protocol::HTTP::Response] The response.
			# @returns [Boolean] Whether the response is an error without handler-provided headers.
			def unhandled_error?(response)
				response.status >= 400 && response.headers.empty?
			end
			
			# Replace an unhandled error response with its configured error document.
			# @parameter request [Utopia::Request] The request.
			# @returns [Protocol::HTTP::Response] The original or error-document response.
			# @raises [RequestFailure] If the configured error document also fails.
			def call(request)
				response = Response.wrap(@delegate.call(request))
				
				if unhandled_error?(response) && location = @codes[response.status]
					error_request = request.with(method: "GET", path_info: location)
					
					error_response = Response.wrap(@delegate.call(error_request))
					
					if error_response.status >= 400
						raise RequestFailure.new(request.path_info, response.status, location, error_response.status)
					else
						# Feed the error code back with the error document:
						error_response.status = response.status
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
		class ClientRedirect < Protocol::HTTP::Middleware
			# Initialize client-side redirection behavior.
			# @parameter app [Interface(:call)] The downstream application.
			# @parameter status [Integer] The status.
			# @parameter max_age [Integer] The maximum cache age in seconds.
			def initialize(app, status: 307, max_age: DEFAULT_MAX_AGE)
				super(app)
				
				@status = status
				@max_age = max_age
			end
			
			# Freeze this object and its internal state.
			# @returns [self] This object.
			def freeze
				return self if frozen?
				
				@status.freeze
				@max_age.freeze
				
				super
			end
			
			attr :status
			attr :max_age
			
			# Build the cache control header value.
			# @returns [String] The cache-control value.
			def cache_control
				# http://jacquesmattheij.com/301-redirects-a-dangerous-one-way-street
				"max-age=#{self.max_age}"
			end
			
			# Build headers for a client redirect.
			# @parameter location [String] The redirect location.
			# @returns [Hash(String, String)] The redirect headers.
			def make_headers(location)
				{
					HTTP::LOCATION => location,
					HTTP::CACHE_CONTROL => self.cache_control
				}
			end
			
			# Build a redirect response for the given location.
			# @parameter location [String] The redirect location.
			# @returns [Protocol::HTTP::Response] The redirect response.
			def redirect(location)
				return Response[self.status, self.make_headers(location), []]
			end
			
			# Resolve a normalized request path to a redirect response.
			# @parameter path [String] The normalized request path.
			# @returns [Protocol::HTTP::Response | false] The redirect response, or `false` by default.
			def [] path
				false
			end
			
			# Redirect a normalized request path when it matches, otherwise invoke the application.
			# @parameter request [Utopia::Request] The request.
			# @returns [Protocol::HTTP::Response] The redirect or downstream response.
			def call(request)
				# Normalize the path to remove redundant slashes, `.` and `..` segments.
				# This prevents protocol-relative redirect URLs (e.g. //evil.com/index)
				# from being generated when PATH_INFO contains a double leading slash.
				path = Path.create(request.path_info).simplify.to_s
				
				if redirection = self[path]
					return redirection
				end
				
				return @delegate.call(request)
			end
		end
		
		# Redirect urls that end with a `/`, e.g. directories.
		class DirectoryIndex < ClientRedirect
			# Initialize directory-index redirection.
			# @parameter app [Interface(:call)] The downstream application.
			# @parameter index [Integer] The index.
			def initialize(app, index: "index")
				@index = index
				
				super(app)
			end
			
			# Redirect a directory path to its index path.
			# @parameter path [String] The normalized request path.
			# @returns [Protocol::HTTP::Response | Nil] The redirect response when the path ends with `/`.
			def [] path
				if path.end_with?("/")
					return redirect(path + @index)
				end
			end
		end
		
		# Rewrite requests that match the given pattern to a single destination.
		class Rewrite < ClientRedirect
			# Initialize exact-path redirections.
			# @parameter app [Interface(:call)] The downstream application.
			# @parameter patterns [Hash] The path rewrite patterns.
			# @parameter status [Integer] The status.
			def initialize(app, patterns, status: 301)
				@patterns = patterns
				
				super(app, status: status)
			end
			
			# Redirect a path found in the rewrite map.
			# @parameter path [String] The normalized request path.
			# @returns [Protocol::HTTP::Response | Nil] The redirect response when the path is mapped.
			def [] path
				if location = @patterns[path]
					return redirect(location)
				end
			end
		end
		
		# Rewrite requests that match the given pattern to a new prefix.
		class Moved < ClientRedirect
			# Initialize prefix redirection behavior.
			# @parameter app [Interface(:call)] The downstream application.
			# @parameter pattern [Regexp] The path pattern.
			# @parameter prefix [String] The prefix.
			# @parameter status [Integer] The status.
			# @parameter flatten [bool] Whether to flatten the rewritten path.
			def initialize(app, pattern, prefix, status: 301, flatten: false)
				@pattern = pattern
				@prefix = prefix
				@flatten = flatten
				
				super(app, status: status)
			end
			
			# Redirect a matching path to the configured prefix.
			# @parameter path [String] The normalized request path.
			# @returns [Protocol::HTTP::Response | Nil] The redirect response when the pattern matches.
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
