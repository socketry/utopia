# frozen_string_literal: true

# Copyright, 2012, by Samuel G. D. Williams. <http://www.codeotaku.com>
# 
# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:
# 
# The above copyright notice and this permission notice shall be included in
# all copies or substantial portions of the Software.
# 
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
# THE SOFTWARE.

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
