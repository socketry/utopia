# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2014-2025, by Samuel Williams.
# Copyright, 2025, by Olle Jonsson.

require "console"

require_relative "../middleware"
require_relative "../request"
require_relative "../response"

module Utopia
	module Exceptions
		# A middleware which catches exceptions and performs an internal redirect.
		class Handler < Protocol::HTTP::Middleware
			# @param location [String] Peform an internal redirect to this location when an exception is raised.
			def initialize(app, location = "/errors/exception")
				super(app)
				
				@location = location
			end
			
			# Freeze this object and its internal state.
			# @returns [self] This object.
			def freeze
				return self if frozen?
				
				@location.freeze
				
				super
			end
			
			# Convert application exceptions into internal-server-error responses.
			# @parameter request [Utopia::Request] The request.
			# @returns [Protocol::HTTP::Response] The application response or a generated error response.
			def call(request)
				begin
					return @delegate.call(request)
				rescue Exception => exception
					Console.warn(self, "An error occurred while processing the request.", error: exception)
					
					begin
						# We do an internal redirection to the error location:
						error_request = request.with(
							method: "GET",
							url: request.url.with(path: @location)
						)
						error_request.exception = exception
						
						error_response = Response.wrap(@delegate.call(error_request))
						error_response.status = 500
						
						return error_response
					rescue Exception => exception
						# If redirection fails, we also finish with a fatal error:
						Console.error(self, "An error occurred while invoking the error handler.", error: exception)
						return Response[500, {"content-type" => "text/plain"}, ["An error occurred while processing the request."]]
					end
				end
			end
		end
	end
end
