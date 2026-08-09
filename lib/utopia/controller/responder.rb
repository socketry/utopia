# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2020-2025, by Samuel Williams.

require_relative "middleware"

module Utopia
	module Controller
		# @namespace
		module Handlers
			# Serializes controller values as JSON responses.
			module JSON
				APPLICATION_JSON = HTTP::Accept::ContentType.new("application", "json").freeze
				
				# Delegate content-type splitting to the JSON media type.
				# @parameter arguments [Array] The arguments.
				# @returns [Array] The resulting values.
				def self.split(*arguments)
					APPLICATION_JSON.split(*arguments)
				end
				
				# Serialize an object as JSON.
				# @parameter context [Object] The context.
				# @parameter request [Utopia::Request] The request.
				# @parameter media_range [HTTP::Accept::MediaTypes::MediaRange] The negotiated media range.
				# @parameter object [Object] The object.
				# @parameter options [Hash] The options.
				# @returns [String] The serialized JSON body.
				def self.call(context, request, media_range, object, **options)
					if version = media_range.parameters["version"]
						options[:version] = version.to_s
					end
					
					return object.to_json(options)
				end
				
				# The media type produced by this handler.
				# @returns [HTTP::Accept::ContentType] The JSON media type.
				def self.content_type
					APPLICATION_JSON
				end
			end
			
			# Passes response values through without transformation.
			module Passthrough
				WILDCARD = HTTP::Accept::MediaTypes::MediaRange.new("*", "*").freeze
				
				# Delegate content-type splitting to the wildcard media range.
				# @parameter arguments [Array] The arguments.
				# @returns [Array] The resulting values.
				def self.split(*arguments)
					WILDCARD.split(*arguments)
				end
				
				# Pass an object through without transformation.
				# @parameter context [Object] The context.
				# @parameter request [Utopia::Request] The request.
				# @parameter media_range [HTTP::Accept::MediaTypes::MediaRange] The negotiated media range.
				# @parameter object [Object] The object.
				# @parameter options [Hash] The options.
				# @returns [Object] The original body.
				def self.call(context, request, media_range, object, **options)
					return object
				end
				
				# The passthrough handler does not specify a response media type.
				# @returns [Nil] No media type.
				def self.content_type
					return nil
				end
			end
		end
		
		# Negotiates response content types and invokes the matching handler.
		class Responder
			# A content-type handler and its response block.
			Handler = Struct.new(:content_type, :block) do
				# Delegate content-type splitting to this handler's content type.
				# @parameter arguments [Array] The arguments.
				# @returns [Array] The resulting values.
				def split(*arguments)
					self.content_type.split(*arguments)
				end
				
				# Invoke this handler's block in the controller context.
				# @parameter context [Object] The context.
				# @parameter request [Utopia::Request] The request.
				# @parameter media_range [HTTP::Accept::MediaTypes::MediaRange] The negotiated media range.
				# @parameter arguments [Array] The arguments.
				# @parameter options [Hash] The options.
				# @returns [Object] The handler block's result.
				def call(context, request, media_range, *arguments, **options)
					context.instance_exec(media_range, *arguments, **options, &self.block)
				end
			end
			
			# Initialize an empty content-type handler map.
			def initialize
				@handlers = HTTP::Accept::MediaTypes::Map.new
			end
			
			attr :handlers
			
			# Freeze this object and its internal state.
			# @returns [self] This object.
			def freeze
				@handlers.freeze
				
				super
			end
			
			# Negotiate the request's accepted media types and invoke the best handler.
			# @parameter context [Object] The controller context.
			# @parameter request [Utopia::Request] The request.
			# @parameter arguments [Array] The arguments.
			# @parameter options [Hash] The options.
			# @returns [Array(Object, Object) | Nil] The selected content type and body, or `nil` if none matches.
			def call(context, request, *arguments, **options)
				# Parse the list of browser preferred content types and return ordered by priority:
				media_types = HTTP::Accept::MediaTypes.browser_preferred_media_types(
					HTTP::Accept::MediaTypes::HTTP_ACCEPT => Array(request.headers["accept"]).join(",")
				)
				
				handler, media_range = @handlers.for(media_types)
				
				if handler
					return handler.content_type, handler.call(context, request, media_range, *arguments, **options)
				end
				
				return nil
			end
			
			# Add a serializer for the specified content type.
			def handle(content_type, &block)
				@handlers << Handler.new(content_type, block)
			end
			
			# Register the default JSON handler.
			# @returns [HTTP::Accept::MediaTypes::Map] The updated handler map.
			def with_json
				@handlers << Handlers::JSON
			end
			
			# Register the wildcard passthrough handler.
			# @returns [HTTP::Accept::MediaTypes::Map] The updated handler map.
			def with_passthrough
				@handlers << Handlers::Passthrough
			end
			
			# Invoke the responder with the given object.
			# @parameter content_type [String] The content type.
			# @yields The response handler body.
			# @returns [HTTP::Accept::MediaTypes::Map] The updated handler map.
			def with(content_type, &block)
				handle(content_type, &block)
			end
		end
	end
end
