# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2016-2025, by Samuel Williams.

require_relative "../http"
require_relative "../response"
require_relative "responder"

module Utopia
	module Controller
		# A controller layer which provides a convenient way to respond to different requested content types. The order in which you add converters matters, as it determines how the incoming Accept: header is mapped, e.g. the first converter is also defined as matching the media range */*.
		module Respond
			# Extend a controller class with response negotiation.
			# @parameter base [Class] The controller class.
			# @returns [Class] The extended controller class.
			def self.prepended(base)
				base.extend(ClassMethods)
			end
			
			# Defines response handlers on controller classes.
			module ClassMethods
				# Return this controller's responder.
				# @returns [Responder] The responder.
				def responds
					@responder ||= Responder.new
				end
				
				alias respond responds
				
				# Bind this controller's responder to a context and request.
				# @parameter context [Controller::Base] The controller context.
				# @parameter request [Protocol::HTTP::Request] The request.
				# @returns [Responder::Responds | nil] The bound responder, if one has been configured.
				def respond_to(context, request)
					@responder&.respond_to(context, request)
				end
				
				# Build a response for the negotiated content type.
				# @parameter context [Object] The context.
				# @parameter request [Protocol::HTTP::Request] The request.
				# @parameter response [Protocol::HTTP::Response] The response.
				# @returns [Protocol::HTTP::Response] The response.
				def response_for(context, request, response)
					@responder&.respond_to(context, request).with(*response.body)
				end
			end
			
			# Bind this controller's responder to the request.
			# @parameter request [Protocol::HTTP::Request] The request.
			# @returns [Responder::Responds | nil] The bound responder, if one has been configured.
			def respond_to(request)
				self.class.respond_to(self, request)
			end
			
			# Build a response for the negotiated content type.
			# @parameter request [Protocol::HTTP::Request] The request.
			# @parameter original_response [Object] The original response.
			# @returns [Protocol::HTTP::Response] The response.
			def response_for(request, original_response)
				response = catch(:response) do
					self.class.response_for(self, request, original_response)
					
					# If the above code did not throw a new response, we return the original:
					return original_response
				end
				
				# If the user called {Base#ignore!}, it's possible response is nil:
				if response
					# There was an updated response so merge it:
					headers = original_response.headers.dup
					headers.update(response.headers)
					
					return Utopia::Response[original_response.status, headers, response.body || original_response.body]
				end
			end
			
			# Invokes super. If a response is generated, format it based on the Accept: header, unless the content type was already specified.
			def process!(request, path)
				if response = super
					headers = response.headers
					
					# Don't try to convert the response if a content type was explicitly specified.
					if headers[HTTP::CONTENT_TYPE]
						return response
					else
						return self.response_for(request, response)
					end
				end
			end
		end
	end
end
