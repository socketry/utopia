# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2020-2022, by Samuel Williams.

require_relative 'middleware'

module Utopia
	class Responder
		Handler = Struct.new(:content_type, :block) do
			def split(*arguments)
				self.content_type.split(*arguments)
			end
			
			def call(context, request, media_range, *arguments, **options)
				context.instance_exec(media_range, *arguments, **options, &self.block)
			end
		end
		
		Responds = Struct.new(:responder, :context, :request) do
			# @todo Refactor `object` -> `*arguments`...
			def with(object, **options)
				responder.call(context, request, object, **options)
			end
		end
		
		def initialize
			@handlers = HTTP::Accept::MediaTypes::Map.new
		end
		
		attr :handlers
		
		def freeze
			@handlers.freeze
			
			super
		end
		
		def call(context, request, *arguments, **options)
			# Parse the list of browser preferred content types and return ordered by priority:
			media_types = HTTP::Accept::MediaTypes.browser_preferred_media_types(request.env)
			
			handler, media_range = @handlers.for(media_types)
			
			if handler
				handler.call(context, request, media_range, *arguments, **options)
			end
		end
		
		# Add a converter for the specified content type. Call the block with the response content if the request accepts the specified content_type.
		def handle(content_type, &block)
			@handlers << Handler.new(content_type, block)
		end
		
		def respond_to(context, request)
			Responds.new(self, context, request)
		end
	end
end
