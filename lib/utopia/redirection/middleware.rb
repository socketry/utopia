# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2026, by Samuel Williams.

require_relative "../middleware"
require_relative "../request"
require_relative "../response"

module Utopia
	module Redirection
		# Applies configured request redirections and error documents.
		class Middleware < Protocol::HTTP::Middleware
			# Initialize redirection handling.
			# @parameter delegate [Protocol::HTTP::Middleware] The downstream middleware.
			# @parameter builder [Builder] The configured redirection builder.
			def initialize(delegate, builder)
				super(delegate)
				
				@rules = builder.rules
				@errors = builder.errors
			end
			
			# Build a redirect response for the given rule and location.
			# @parameter rule [Object] The matching redirection rule.
			# @parameter location [String] The redirect destination.
			# @returns [Protocol::HTTP::Response] The redirect response.
			def redirect(rule, location)
				headers = {
					HTTP::LOCATION => location,
					HTTP::CACHE_CONTROL => "max-age=#{rule.max_age}"
				}
				
				return Response[rule.status, headers, []]
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
				
				error_request = request.with(method: "GET", path_info: location)
				error_response = Response.wrap(@delegate.call(error_request))
				
				if error_response.status >= 400
					error = RequestFailure.new(request.path_info, resource_status, location, error_response.status)
					
					# The failed error document will not be returned to the server:
					error_response.close(error)
					
					raise error
				end
				
				# Feed the error code back with the error document:
				error_response.status = resource_status
				return error_response
			end
			
			# Apply request redirections, invoke the delegate, and handle error responses.
			# @parameter request [Utopia::Request] The request.
			# @returns [Protocol::HTTP::Response] The resulting response.
			def call(request)
				# Normalize the path once to remove redundant slashes and dot segments:
				path = Path.create(request.path_info).simplify.to_s
				
				@rules.each do |rule|
					if location = rule.call(path)
						return redirect(rule, location)
					end
				end
				
				response = Response.wrap(@delegate.call(request))
				
				if unhandled_error?(response) && location = @errors[response.status]
					return replace_error(request, response, location)
				end
				
				return response
			end
		end
	end
end
