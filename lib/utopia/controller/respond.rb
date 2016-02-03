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
		# This controller layer provides a convenient way to respond to different requested content types.
		module Respond
			def self.prepended(base)
				base.extend(ClassMethods)
			end
			
			# A specific conversion to a given content_type, e.g. 'application/json'.
			class Converter
				def initialize(content_type, block)
					@content_type = content_type
					@block = block
					
					self.freeze
				end
				
				def freeze
					@content_type.freeze
					@block.freeze
					
					super
				end
				
				attr :content_type
				attr :block
				
				# Given a specific context, modify the response to suit the given `content_type`.
				def apply(context, response)
					status, headers, body = response
					
					# Generate a new body:
					body = body.collect{|content| context.instance_exec(content, &@block)}
					
					# Update the headers with the requested content type:
					headers = headers.merge(HTTP::CONTENT_TYPE => @content_type)
					
					return [status, headers, body]
				end
			end
			
			# Contains a set of converters which can be queried 
			class Converters
				WILDCARD = '*'.freeze
				
				def initialize
					@media_types = Hash.new{|h,k| h[k] = {}}
				end
				
				def freeze
					@media_types.freeze
					@media_types.each{|key,value| value.freeze}
					
					super
				end
				
				# Given a list of content types (e.g. from browser_preferred_content_types), return the best converter.
				def for(patterns)
					patterns.each do |pattern|
						type, subtype = pattern.split('/')
						
						if converter = @media_types[type][subtype]
							return converter
						end
					end
					
					return nil
				end
				
				# Add a converter to the collection.
				def << converter
					type, subtype = converter.content_type.split('/')
					
					if @media_types.empty?
						@media_types[WILDCARD][WILDCARD] = converter
					end
					
					if @media_types[type].empty?
						@media_types[type][WILDCARD] = converter
					end
					
					@media_types[type][subtype] = converter
				end
			end
			
			class Responder
				HTTP_ACCEPT = 'HTTP_ACCEPT'.freeze
				NOT_ACCEPTABLE_RESPONSE = [406, {}, []].freeze
				
				TO_JSON = Converter.new('application/json', lambda{|content| content.to_json}).freeze
				TO_YAML = Converter.new('application/x-yaml', lambda{|content| content.to_yaml}).freeze
				
				def initialize
					@converters = Converters.new
					@otherwise = nil
				end
				
				def freeze
					@converters.freeze
					@otherwise.freeze
					
					super
				end
				
				# Parse the list of browser preferred content types and return ordered by priority.
				def browser_preferred_content_types(env)
					if accept_content_types = env[HTTP_ACCEPT]
						return HTTP::prioritised_list(accept_content_types)
					else
						return []
					end
				end
				
				# Add a converter for the specified content type. Call the block with the response content if the request accepts the specified content_type.
				def with(content_type, &block)
					@converters << Converter.new(content_type, block)
				end
				
				# Add a converter for JSON when requests accept 'application/json'
				def with_json
					@converters << TO_JSON
				end
				
				# Add a converter for YAML when requests accept 'application/x-yaml'.
				def with_yaml
					@converters << TO_YAML
				end
				
				# If the content type could not be matched, invoke the provided block and use it's result as the response.
				def otherwise(&block)
					@otherwise = block
				end
				
				# If the content type could not be matched, ignore it and don't use the result of the controller layer.
				def otherwise_passthrough
					@otherwise = proc { nil }
				end
				
				def call(context, request, path, response)
					content_types = browser_preferred_content_types(request.env)
					
					converter = @converters.for(content_types)
					
					if converter
						converter.apply(context, response)
					else
						not_acceptable_response(context, response)
					end
				end
				
				# Generate a not acceptable response which unless customised with `otherwise`, will result in a generic 406 Not Acceptable response.
				def not_acceptable_response(context, response)
					if @otherwise
						context.instance_exec(response, &@otherwise)
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
			
			# Rewrite the path before processing the request if possible.
			def passthrough(request, path)
				if response = super
					self.class.response_for(self, request, path, response)
				end
			end
		end
	end
end
