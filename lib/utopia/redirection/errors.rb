# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2026, by Samuel Williams.

require_relative "../middleware"
require_relative "../request"
require_relative "../response"
require_relative "request_failure"

module Utopia
	module Redirection
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
			# @parameter response [Protocol::HTTP::Response] The unhandled error response.
			# @parameter location [String] The configured error document path.
			# @returns [Protocol::HTTP::Response] The error-document response.
			# @raises [RequestFailure] If the configured error document also fails.
			def replace_error(request, response, location)
				resource_status = response.status
				
				# The original response is replaced by the configured error document:
				response.close
				
				error_request = request.with(method: "GET", url: request.url.with(path: location))
				error_response = Response.wrap(@delegate.call(error_request))
				
				if error_response.status >= 400
					error = RequestFailure.new(request.url.path.encoded, resource_status, location, error_response.status)
					
					# The failed error document will not be returned to the server:
					error_response.close(error)
					
					raise error
				end
				
				# Feed the error code back with the error document:
				error_response.status = resource_status
				return error_response
			end
			
			# Replace configured unhandled responses through an internal request.
			# @parameter request [Utopia::Request] The request.
			# @returns [Protocol::HTTP::Response] The original or error-document response.
			def call(request)
				response = Response.wrap(@delegate.call(request))
				
				if unhandled_error?(response) && location = @codes[response.status]
					return replace_error(request, response, location)
				end
				
				return response
			end
		end
	end
end
