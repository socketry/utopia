# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2026, by Samuel Williams.

module Utopia
	# The application-facing request wrapper.
	#
	# This class intentionally keeps a small surface area. Framework features such
	# as arguments, sessions, localization and controller variables should be added
	# as explicit Utopia concepts rather than relying on a Rack-style env hash.
	class Request
		# Initialize a request wrapper.
		# @parameter http [Protocol::HTTP::Request] The underlying protocol request.
		# @parameter attributes [Hash | Nil] Request-local application state.
		def initialize(http, attributes: nil)
			@http = http
			@attributes = attributes || {}
		end
		
		# The underlying {Protocol::HTTP::Request}.
		attr :http
		
		# Request-local application state.
		attr :attributes
		
		# @returns [String] The HTTP request method.
		def method
			@http.method
		end
		
		# @returns [String] The full request path, including query string.
		def path
			@http.path
		end
		
		# Set the full request path.
		# @parameter value [String] The full request path, including optional query string.
		def path=(value)
			@http.path = value
		end
		
		# @returns [String | Nil] The request path without query string.
		def path_info
			@http.path&.split("?", 2)&.first
		end
		
		# Set the request path while preserving the current query string.
		# @parameter value [String] The request path without query string.
		def path_info=(value)
			if query = self.query
				@http.path = "#{value}?#{query}"
			else
				@http.path = value
			end
		end
		
		# @returns [String | Nil] The query string without the leading `?`.
		def query
			@http.path&.split("?", 2)&.last if @http.path&.include?("?")
		end
		
		# @returns [Protocol::HTTP::Headers] The request headers.
		def headers
			@http.headers
		end
		
		# @returns [Protocol::HTTP::Body::Readable | Nil] The request body.
		def body
			@http.body
		end
	end
end
