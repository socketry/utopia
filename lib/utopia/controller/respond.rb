# frozen_string_literal: true

# Copyright, 2016, by Samuel G. D. Williams. <http://www.codeotaku.com>
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

require_relative '../http'
require_relative '../responder'

module Utopia
	class Controller
		# A controller layer which provides a convenient way to respond to different requested content types. The order in which you add converters matters, as it determines how the incoming Accept: header is mapped, e.g. the first converter is also defined as matching the media range */*.
		module Respond
			def self.prepended(base)
				base.extend(ClassMethods)
			end
			
			module Handlers
				module JSON
					APPLICATION_JSON = HTTP::Accept::ContentType.new('application', 'json').freeze
					
					def self.split(*arguments)
						APPLICATION_JSON.split(*arguments)
					end
					
					def self.call(context, request, media_range, object, **options)
						if version = media_range.parameters['version']
							options[:version] = version.to_s
						end
						
						context.succeed! content: object.to_json(options), type: APPLICATION_JSON
					end
				end
				
				module Passthrough
					WILDCARD = HTTP::Accept::MediaTypes::MediaRange.new('*', '*').freeze
					
					def self.split(*arguments)
						WILDCARD.split(*arguments)
					end
					
					def self.call(context, request, media_range, object, **options)
						context.ignore!
					end
				end
			end
			
			class Responder < Utopia::Responder
				def with_json
					@handlers << Handlers::JSON
				end
				
				def with_passthrough
					@handlers << Handlers::Passthrough
				end
				
				def with(content_type, &block)
					handle(content_type, &block)
				end
			end
			
			module ClassMethods
				def responds
					@responder ||= Responder.new
				end
				
				alias respond responds
				
				def respond_to(context, request)
					@responder&.respond_to(context, request)
				end
				
				def response_for(context, request, response)
					@responder&.respond_to(context, request).with(*response[2])
				end
			end
			
			def respond_to(request)
				self.class.respond_to(self, request)
			end
			
			def response_for(request, original_response)
				response = catch(:response) do
					self.class.response_for(self, request, original_response)
					
					# If the above code did not throw a new response, we return the original:
					return original_response
				end
				
				# If the user called {Base#ignore!}, it's possible response is nil:
				if response
					# There was an updated response so merge it:
					return [original_response[0], original_response[1].merge(response[1]), response[2] || original_response[2]]
				end
			end
			
			# Invokes super. If a response is generated, format it based on the Accept: header, unless the content type was already specified.
			def process!(request, path)
				if response = super
					headers = response[1]
					
					# Don't try to convert the response if a content type was explicitly specified.
					if headers[HTTP::CONTENT_TYPE]
						return response
					else
						self.response_for(request, response)
					end
				end
			end
		end
	end
end
