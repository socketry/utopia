# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2014-2025, by Samuel Williams.
# Copyright, 2025, by Olle Jonsson.

require "console"

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
			
			def call(env)
				begin
					return @app.call(env)
				rescue Exception => exception
					Console.warn(self, "An error occurred while processing the request.", error: exception)
					
					begin
						# We do an internal redirection to the error location:
						error_request = env.merge(
							Rack::PATH_INFO => @location,
							Rack::REQUEST_METHOD => Rack::GET,
							"utopia.exception" => exception,
						)
						
						error_response = @app.call(error_request)
						error_response[0] = 500
						
						return error_response
					rescue Exception => exception
						# If redirection fails, we also finish with a fatal error:
						Console.error(self, "An error occurred while invoking the error handler.", error: exception)
						return [500, {"content-type" => "text/plain"}, ["An error occurred while processing the request."]]
					end
				end
			end
		end
	end
end
