# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2009-2026, by Samuel Williams.

require "protocol/http/middleware"

require_relative "../response"

module Utopia
	# Redirects requests and error responses to configured locations.
	module Redirection
		# The common implementation for client-visible redirects.
		class ClientRedirect < Protocol::HTTP::Middleware
			# The default redirect cache lifetime is 24 hours.
			MAX_AGE = 3600*24
			
			# Initialize client-side redirection behavior.
			# @parameter delegate [Protocol::HTTP::Middleware] The downstream middleware.
			# @parameter status [Integer] The redirect response status.
			# @parameter max_age [Integer] The redirect cache lifetime in seconds.
			def initialize(delegate, status: 307, max_age: MAX_AGE)
				super(delegate)
				
				@status = status
				@max_age = max_age
			end
			
			# Freeze this object and its internal state.
			# @returns [self] This object.
			def freeze
				return self if frozen?
				
				@status.freeze
				@max_age.freeze
				
				return super
			end
			
			# The redirect response status.
			attr :status
			
			# The redirect cache lifetime in seconds.
			attr :max_age
			
			# Build the cache-control header value.
			# @returns [String] The cache-control value.
			def cache_control
				# http://jacquesmattheij.com/301-redirects-a-dangerous-one-way-street
				return "max-age=#{self.max_age}"
			end
			
			# Build headers for a client redirect.
			# @parameter location [String] The redirect location.
			# @returns [Hash(String, String)] The redirect headers.
			def make_headers(location)
				return {
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
			def [](path)
				return false
			end
			
			# Redirect a matching request path, otherwise invoke the delegate.
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
