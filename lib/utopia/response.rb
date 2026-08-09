# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2026, by Samuel Williams.

require "protocol/http/response"
require "protocol/http/middleware"

module Utopia
	# Response helpers for Utopia applications.
	#
	# The canonical transport response remains {Protocol::HTTP::Response}. This
	# module provides convenience constructors and normalization at the application
	# boundary.
	module Response
		CONTENT_TYPE = "content-type".freeze
		LOCATION = "location".freeze
		
		NotFound = Protocol::HTTP::Middleware::NotFound
		
		# Build a protocol HTTP response.
		# @parameter status [Integer] The HTTP status code.
		# @parameter headers [Hash | Protocol::HTTP::Headers | Nil] The response headers.
		# @parameter body [Object] The response body.
		# @parameter options [Hash] Additional options passed to `Protocol::HTTP::Response[]`.
		# @returns [Protocol::HTTP::Response] The response object.
		def self.[](status, headers = nil, body = nil, **options)
			Protocol::HTTP::Response[status, headers, body, **options]
		end
		
		# Normalize a response-like value to a protocol response.
		# @parameter response [Object] The response-like value.
		# @returns [Protocol::HTTP::Response] The normalized response.
		# @raises [TypeError] If the response cannot be normalized.
		def self.wrap(response)
			return response if response.is_a?(Protocol::HTTP::Response)
			
			if response.respond_to?(:to_response)
				response = response.to_response
				return response if response.is_a?(Protocol::HTTP::Response)
			end
			
			raise TypeError, "Expected a Protocol::HTTP::Response, but got #{response.class}!"
		end
		
		# Build a redirect response.
		# @parameter location [String] The redirect location.
		# @parameter status [Integer] The redirect status code.
		# @parameter headers [Hash] Additional response headers.
		# @returns [Protocol::HTTP::Response] The redirect response.
		def self.redirect(location, status = 302, headers = {})
			self[status, headers.merge(LOCATION => location), []]
		end
		
		# Build a plain text response.
		# @parameter content [String] The response content.
		# @parameter status [Integer] The response status.
		# @parameter headers [Hash] Additional response headers.
		# @returns [Protocol::HTTP::Response] The text response.
		def self.text(content, status = 200, headers = {})
			self[status, {CONTENT_TYPE => "text/plain; charset=utf-8"}.merge(headers), [content]]
		end
		
		# Build an HTML response.
		# @parameter content [String] The response content.
		# @parameter status [Integer] The response status.
		# @parameter headers [Hash] Additional response headers.
		# @returns [Protocol::HTTP::Response] The HTML response.
		def self.html(content, status = 200, headers = {})
			self[status, {CONTENT_TYPE => "text/html; charset=utf-8"}.merge(headers), [content]]
		end
	end
end
