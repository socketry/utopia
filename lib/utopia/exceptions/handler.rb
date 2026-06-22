# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2014-2025, by Samuel Williams.
# Copyright, 2025, by Olle Jonsson.

require "console"

require_relative "../middleware"
require_relative "../response"

module Utopia
	module Exceptions
		# A middleware which catches exceptions and performs an internal redirect.
		class Handler
			# @param location [String] Peform an internal redirect to this location when an exception is raised.
			def initialize(app, location = "/errors/exception")
				@app = app
				
				@location = location
			end
			
			def freeze
				return self if frozen?
				
				@location.freeze
				
				super
			end
			
			def call(request)
				legacy = Utopia::Middleware.legacy_request?(request)
				request = Utopia::Middleware.request(request)
				
				begin
					return Utopia::Middleware.response(@app.call(request), legacy)
				rescue Exception => exception
					Console.warn(self, "An error occurred while processing the request.", error: exception)
					
					begin
						# We do an internal redirection to the error location:
						error_request = request.with(
							method: "GET",
							path_info: @location,
							attributes: {"utopia.exception" => exception}
						)
						
						error_response = Response.wrap(@app.call(error_request))
						error_response.status = 500
						
						return Utopia::Middleware.response(error_response, legacy)
					rescue Exception => exception
						# If redirection fails, we also finish with a fatal error:
						Console.error(self, "An error occurred while invoking the error handler.", error: exception)
						return Utopia::Middleware.response(Response[500, {"content-type" => "text/plain"}, ["An error occurred while processing the request."]], legacy)
					end
				end
			end
		end
	end
end
