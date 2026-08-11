# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2026, by Samuel Williams.

require_relative "../middleware"
require_relative "../response"

module Utopia
	# A middleware which assists with redirecting from one path to another.
	module Redirection
		# We cache 301 redirects for 24 hours.
		MAX_AGE = 3600*24
		
		# A basic client-side redirect.
		class ClientRedirect < Protocol::HTTP::Middleware
			# Initialize client-side redirection behavior.
			# @parameter app [Interface(:call)] The downstream application.
			# @parameter status [Integer] The status.
			# @parameter max_age [Integer] The maximum cache age in seconds.
			def initialize(app, status: 307, max_age: MAX_AGE)
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
			
			# Redirect a matching request path, otherwise invoke the application.
			# @parameter request [Utopia::Request] The normalized request.
			# @returns [Protocol::HTTP::Response] The redirect or downstream response.
			def call(request)
				if redirection = self[request.url.path.encoded]
					return redirection
				end
				
				return super
			end
		end
	end
end
