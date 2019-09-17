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
require_relative '../path/matcher'

module Utopia
	class Controller
		# A controller layer which provides a convenient way to respond to different requested content types. The order in which you add converters matters, as it determines how the incoming Accept: header is mapped, e.g. the first converter is also defined as matching the media range */*.
		module Respond
			def self.prepended(base)
				base.extend(ClassMethods)
			end
			
			module Converter
				def self.update_response(response, updated_headers)
					status, headers, body = response
					
					# Generate a new body:
					body = body.collect{|content| yield content}
					
					# Update the headers with the requested content type:
					headers = headers.merge(updated_headers)
					
					return [status, headers, body]
				end
				
				Callback = Struct.new(:content_type, :block) do
					def headers
						{HTTP::CONTENT_TYPE => self.content_type}
					end
					
					def split(*args)
						self.content_type.split(*args)
					end
					
					def call(context, response, media_range)
						Converter.update_response(response, headers) do |content|
							context.instance_exec(content, media_range, &block)
						end
					end
				end
				
				def self.new(*args)
					Callback.new(*args)
				end
				
				# To accept incoming requests with content-type JSON (e.g. POST with JSON data), consider using `Rack::PostBodyContentTypeParser`.
				module ToJSON
					APPLICATION_JSON = HTTP::Accept::ContentType.new('application', 'json', charset: 'utf-8').freeze
					HEADERS = {HTTP::CONTENT_TYPE => APPLICATION_JSON.to_s}.freeze
					
					def self.content_type
						APPLICATION_JSON
					end
					
					def self.split(*args)
						self.content_type.split(*args)
					end
					
					def self.serialize(content, media_range)
						options = {}
						
						if version = media_range.parameters['version']
							options[:version] = version.to_s
						end
						
						return content.to_json(options)
					end
					
					def self.call(context, response, media_range)
						Converter.update_response(response, HEADERS) do |content|
							self.serialize(content, media_range)
						end
					end
				end
			end
			
			module Passthrough
				WILDCARD = HTTP::Accept::MediaTypes::MediaRange.new('*', '*').freeze
				
				def self.split(*args)
					self.media_range.split(*args)
				end
				
				def self.media_range
					WILDCARD
				end
				
				def self.call(context, response, media_range)
					return nil
				end
			end
			
			class Responder
				HTTP_ACCEPT = 'HTTP_ACCEPT'.freeze
				NOT_ACCEPTABLE_RESPONSE = [406, {}, []].freeze
				
				def initialize
					@converters = HTTP::Accept::MediaTypes::Map.new
				end
				
				def freeze
					@converters.freeze
					
					super
				end
				
				# Add a converter for the specified content type. Call the block with the response content if the request accepts the specified content_type.
				def with(content_type, &block)
					@converters << Converter::Callback.new(content_type, block)
				end
				
				def with_passthrough
					@converters << Passthrough
				end
				
				# Add a converter for JSON when requests accept 'application/json'
				def with_json
					@converters << Converter::ToJSON
				end
				
				def call(context, request, path, response)
					# Parse the list of browser preferred content types and return ordered by priority:
					media_types = HTTP::Accept::MediaTypes.browser_preferred_media_types(request.env)
					
					converter, media_range = @converters.for(media_types)
					
					if converter
						converter.call(context, response, media_range)
					else
						NOT_ACCEPTABLE_RESPONSE
					end
				end
			end
			
			module ClassMethods
				def respond
					@responder ||= Responder.new
				end
				
				def response_for(context, request, path, response)
					if @responder
						@responder.call(context, request, path, response)
					else
						response
					end
				end
			end
			
			# Invokes super. If a response is generated, format it based on the Accept: header, unless the content type was already specified.
			def process!(request, path)
				if response = super
					headers = response[1]
					
					# Don't try to convert the response if a content type was explicitly specified.
					unless headers[Rack::CONTENT_TYPE]
						response = self.class.response_for(self, request, path, response)
					end
					
					response
				end
			end
		end
	end
end
