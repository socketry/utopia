# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2020-2025, by Samuel Williams.

require_relative "middleware"

require "protocol/http/header/accept"
require "protocol/media/map"
require "protocol/media/type"
require "protocol/media/range"

module Utopia
	module Controller
		# @namespace
		module Handlers
			# Serializes controller values as JSON responses.
			module JSON
				APPLICATION_JSON = Protocol::Media::Type.new("application", "json").freeze
				
				# Serialize an object as a successful JSON response.
				# @parameter context [Object] The context.
				# @parameter request [Protocol::HTTP::Request] The request.
				# @parameter media_range [Protocol::HTTP::Header::Accept::MediaRange] The negotiated media range.
				# @parameter object [Object] The object.
				# @parameter options [Hash] The options.
				# @returns [Object] The result of {Controller::Base#succeed!}.
				def self.call(context, request, media_range, object, **options)
					if version = media_range.parameters["version"]
						options[:version] = version.to_s
					end
					
					context.succeed! content: object.to_json(options), type: APPLICATION_JSON
				end
			end
			
			# Passes response values through without transformation.
			module Passthrough
				WILDCARD = Protocol::Media::Range.new("*", "*").freeze
				
				# Accept an object without producing a response.
				# @parameter context [Object] The context.
				# @parameter request [Protocol::HTTP::Request] The request.
				# @parameter media_range [Protocol::HTTP::Header::Accept::MediaRange] The negotiated media range.
				# @parameter object [Object] The object.
				# @parameter options [Hash] The options.
				# @returns [nil] No response is produced.
				def self.call(context, request, media_range, object, **options)
					# Do nothing.
				end
			end
		end
		
		# Negotiates response content types and invokes the matching handler.
		class Responder
			# A content-type handler and its response block.
			Handler = Struct.new(:content_type, :block) do
				# Invoke this handler's block in the controller context.
				# @parameter context [Object] The context.
				# @parameter request [Protocol::HTTP::Request] The request.
				# @parameter media_range [Protocol::HTTP::Header::Accept::MediaRange] The negotiated media range.
				# @parameter arguments [Array] The arguments.
				# @parameter options [Hash] The options.
				# @returns [Object] The handler block's result.
				def call(context, request, media_range, *arguments, **options)
					context.instance_exec(media_range, *arguments, **options, &self.block)
				end
			end
			
			# A response invocation bound to its responder, context, and request.
			Responds = Struct.new(:responder, :context, :request) do
				# @todo Refactor `object` -> `*arguments`...
				def with(object, **options)
					responder.call(context, request, object, **options)
				end
			end
			
			# Initialize an empty content-type handler map.
			def initialize
				@handlers = Protocol::Media::Map.new
			end
			
			attr :handlers
			
			# Freeze this object and its internal state.
			# @returns [self] This object.
			def freeze
				@handlers.freeze
				
				super
			end
			
			# Negotiate the request's accepted media types and invoke the best handler.
			# @parameter context [Object] The context.
			# @parameter request [Protocol::HTTP::Request] The request.
			# @parameter arguments [Array] The arguments.
			# @parameter options [Hash] The options.
			# @returns [Object | nil] The selected handler's result, or `nil` if none matches.
			def call(context, request, *arguments, **options)
				if accept = request.headers["accept"]
					media_types = accept.media_ranges.sort
				else
					media_types = [Handlers::Passthrough::WILDCARD]
				end
				
				handler, media_range = @handlers.for(media_types)
				
				if handler
					handler.call(context, request, media_range, *arguments, **options)
				end
			end
			
			# Add a converter for the specified content type. Call the block with the response content if the request accepts the specified content_type.
			def handle(content_type, &block)
				@handlers[content_type] = Handler.new(content_type, block)
				return @handlers
			end
			
			# Bind this responder to a context and request.
			# @parameter context [Controller::Base] The controller context.
			# @parameter request [Protocol::HTTP::Request] The request.
			# @returns [Responds] The bound responder.
			def respond_to(context, request)
				Responds.new(self, context, request)
			end
			
			# Register the default JSON handler.
			# @returns [Protocol::Media::Map] The updated handler map.
			def with_json
				@handlers[Handlers::JSON::APPLICATION_JSON] = Handlers::JSON
				return @handlers
			end
			
			# Register the wildcard passthrough handler.
			# @returns [Protocol::Media::Map] The updated handler map.
			def with_passthrough
				@handlers[Handlers::Passthrough::WILDCARD] = Handlers::Passthrough
				return @handlers
			end
			
			# Invoke the responder with the given object.
			# @parameter content_type [String] The content type.
			# @yields The response handler body.
			# @returns [Protocol::Media::Map] The updated handler map.
			def with(content_type, &block)
				handle(content_type, &block)
			end
		end
	end
end
