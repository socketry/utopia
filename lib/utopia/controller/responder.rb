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
				
				# Serialize an object as JSON.
				# @parameter context [Object] The context.
				# @parameter request [Utopia::Request] The request.
				# @parameter media_range [Protocol::HTTP::Header::Accept::MediaRange] The negotiated media range.
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
				# @returns [Protocol::Media::Type] The JSON media type.
				def self.content_type
					APPLICATION_JSON
				end
			end
			
			# Passes response values through without transformation.
			module Passthrough
				WILDCARD = Protocol::Media::Range.new("*", "*").freeze
				
				# Pass an object through without transformation.
				# @parameter context [Object] The context.
				# @parameter request [Utopia::Request] The request.
				# @parameter media_range [Protocol::HTTP::Header::Accept::MediaRange] The negotiated media range.
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
				# Invoke this handler's block in the controller context.
				# @parameter context [Object] The context.
				# @parameter request [Utopia::Request] The request.
				# @parameter media_range [Protocol::HTTP::Header::Accept::MediaRange] The negotiated media range.
				# @parameter arguments [Array] The arguments.
				# @parameter options [Hash] The options.
				# @returns [Object] The handler block's result.
				def call(context, request, media_range, *arguments, **options)
					context.instance_exec(media_range, *arguments, **options, &self.block)
				end
			end
			
			# Initialize a responder with a handler map.
			# @parameter handlers [Protocol::Media::Map] The response handlers.
			# @parameter passthrough [Object | Nil] The fallback response handler.
			def initialize(handlers = Protocol::Media::Map.new, passthrough = nil)
				@handlers = handlers
				@passthrough = passthrough
			end
			
			attr :handlers
			
			# Freeze this responder and compile its handler map.
			# @returns [self] This responder.
			def freeze
				return self if frozen?
				
				@handlers.freeze
				
				return super
			end
			
			# Add a serializer for the specified content type.
			# @parameter content_type [String | Protocol::Media::Type] The produced media type.
			# @yields The response handler body.
			# @returns [self] This responder.
			def handle(content_type, &block)
				@handlers[content_type] = Handler.new(content_type, block).freeze
				return self
			end
			
			# Register the default JSON handler.
			# @returns [self] This responder.
			def with_json
				@handlers[Handlers::JSON::APPLICATION_JSON] = Handlers::JSON
				return self
			end
			
			# Register the wildcard passthrough handler.
			# @returns [self] This responder.
			def with_passthrough
				@passthrough = Handlers::Passthrough
				return self
			end
			
			# Add a serializer for the specified content type.
			# @parameter content_type [String | Protocol::Media::Type] The produced media type.
			# @yields The response handler body.
			# @returns [self] This responder.
			def with(content_type, &block)
				return handle(content_type, &block)
			end
			
			# Negotiate the request's accepted media types and invoke the best handler.
			# @parameter context [Object] The controller context.
			# @parameter request [Utopia::Request] The request.
			# @parameter arguments [Array] The arguments.
			# @parameter options [Hash] The options.
			# @returns [Array(Object, Object) | Nil] The selected content type and body, or `nil` if none matches.
			def call(context, request, *arguments, **options)
				accept = request.headers["accept"]
				
				# An absent or empty Accept header accepts any media type:
				if accept.nil? || accept.empty?
					media_ranges = [Handlers::Passthrough::WILDCARD]
				else
					media_ranges = accept.preferred_media_ranges
				end
				
				if match = @handlers.for(media_ranges)
					handler, media_range = match
				elsif @passthrough
					handler = @passthrough
					media_range = media_ranges.first
				end
				
				if handler
					return handler.content_type, handler.call(context, request, media_range, *arguments, **options)
				end
				
				return nil
			end
		end
	end
end
