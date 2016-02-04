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
			
			module Converter
				def self.update_response(response, updated_headers)
					status, headers, body = response
					
					# Generate a new body:
					body = body.collect{|content| yield content}
					
					# Update the headers with the requested content type:
					headers = headers.merge(updated_headers)
					
					return [status, headers, body]
				end
				
				class Callback < Struct.new(:content_type, :block)
					def headers
						{HTTP::CONTENT_TYPE => self.content_type}
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
				
				module ToJSON
					APPLICATION_JSON = 'application/json'.freeze
					HEADERS = {HTTP::CONTENT_TYPE => APPLICATION_JSON}.freeze
					
					def self.content_type
						APPLICATION_JSON
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
			
			# Contains a set of converters which can be queried 
			class Converters
				WILDCARD = '*'.freeze
				
				def initialize
					@media_types = Hash.new{|h,k| h[k] = {}}
					
					# Primarily for implementing #freeze efficiently.
					@all = []
				end
				
				def freeze
					@media_types.freeze
					@media_types.each{|key,value| value.freeze}
					
					@all.freeze
					@all.each(&:freeze)
					
					super
				end
				
				# Given a list of content types (e.g. from browser_preferred_content_types), return the best converter.
				def for(media_types)
					media_types.each do |media_range|
						type, subtype = media_range.split
						
						if converter = @media_types[type][subtype]
							return converter, media_range
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
					@all << converter
				end
			end
			
			class Responder
				HTTP_ACCEPT = 'HTTP_ACCEPT'.freeze
				NOT_ACCEPTABLE_RESPONSE = [406, {}, []].freeze
				
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
				def browser_preferred_media_types(env)
					if accept_content_types = env[HTTP_ACCEPT]
						HTTP::Accept::MediaTypes.parse(accept_content_types)
					else
						return []
					end
				end
				
				# Add a converter for the specified content type. Call the block with the response content if the request accepts the specified content_type.
				def with(content_type, &block)
					@converters << Converter::Callback.new(content_type, block)
				end
				
				# Add a converter for JSON when requests accept 'application/json'
				def with_json
					@converters << Converter::ToJSON
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
					media_types = browser_preferred_media_types(request.env)
					
					converter, media_range = @converters.for(media_types)
					
					if converter
						converter.call(context, response, media_range)
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
