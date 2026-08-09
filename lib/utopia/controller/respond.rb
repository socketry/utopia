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
				
				# Serialize a semantic value according to the request's accepted media types.
				# @parameter context [Controller::Base] The controller context.
				# @parameter request [Utopia::Request] The request.
				# @parameter value [Object] The semantic value.
				# @returns [Array(Object, Object) | Nil] The selected content type and body.
				def response_for(context, request, value)
					@responder&.call(context, request, value)
				end
			end
			
			# Build a protocol response for a semantic controller result.
			# @parameter request [Utopia::Request] The request.
			# @parameter result [Controller::Result] The semantic controller result.
			# @returns [Protocol::HTTP::Response] The response.
			def response_for(request, result)
				if response = self.class.response_for(self, request, result.value)
					content_type, body = response
					headers = result.headers.dup
					
					if content_type
						headers[HTTP::CONTENT_TYPE] = content_type.to_s
					end
					
					return Utopia::Response[result.status, headers, body]
				end
				
				raise TypeError, "Could not negotiate a response for #{result.value.class}!"
			end
			
			# Serialize semantic controller results, while passing complete protocol responses through unchanged.
			def process!(request, path)
				result = super
				
				case result
				when Result
					return self.response_for(request, result)
				else
					return result
				end
			end
		end
	end
end
