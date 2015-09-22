# Copyright, 2014, by Samuel G. D. Williams. <http://www.codeotaku.com>
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

module Utopia
	class Controller
		EMPTY_BODY = [].freeze
		
		class Base
			def self.base_path
				self.const_get(:BASE_PATH)
			end
		
			def self.uri_path
				self.const_get(:URI_PATH)
			end
		
			def self.controller
				self.const_get(:CONTROLLER)
			end
			
			class << self
				def direct?(path)
					path.dirname == uri_path
				end
				
				def patterns
					@patterns ||= []
				end
				
				def match(pattern, &block)
					patterns << [pattern, block]
				end
				
				def actions
					@actions ||= Action.new
				end
				
				def on(first, *path, **options, &block)
					if first.is_a? Symbol
						first = ['**', first]
					end
					
					actions.define(Path.split(first) + path, options, &block)
				end
				
				def lookup(path)
					relative_path = (path - uri_path).to_a
					
					possible_actions = actions.select(relative_path)
				end
			end
			
			# Given a path, look up all matched actions.
			def actions_for_request(request, path)
				self.class.lookup(path)
			end
			
			def catch_response
				response = catch(:response) do
					yield and nil
				end
				
				if response
					return self.respond_with(*response)
				end
			end
			
			# Given a request, call associated actions if at least one exists.
			def passthrough(request, path)
				actions = actions_for_request(request, path)
				
				unless actions.empty?
					return catch_response do
						actions.each do |action|
							action.invoke!(self, request, path)
						end
					end
				end
				
				return nil
			end

			# Copy the instance variables from the previous controller to the next controller (usually only a few). This allows controllers to share effectively the same instance variables while still being separate classes/instances.
			def copy_instance_variables(from)
				from.instance_variables.each do |name|
					instance_variable_set(name, from.instance_variable_get(name))
				end
			end

			def call(env)
				self.class.controller.app.call(env)
			end

			def respond!(*args)
				throw :response, args
			end

			def ignore!
				throw :response, nil
			end

			def redirect! (target, status = 302)
				respond! :redirect => target, :status => status
			end

			def fail!(error = :bad_request)
				respond! error
			end

			def success!(*args)
				respond! :success, *args
			end
			
			def respond_with(*args)
				return args[0] if args[0] == nil || Array === args[0]

				status = 200
				options = nil

				if Numeric === args[0] || Symbol === args[0]
					status = args[0]
					options = args[1] || {}
				else
					options = args[0]
					status = options[:status] || status
				end

				status = HTTP::STATUS_CODES[status] || status
				headers = options[:headers] || {}

				if type = options[:type]
					headers[HTTP::CONTENT_TYPE] ||= type
				end

				if redirect = options[:redirect]
					headers[HTTP::LOCATION] = redirect.to_s
					status = 302 if status < 300 || status >= 400
				end

				if options[:body]
					body = options[:body]
				elsif options[:content]
					body = [options[:content]]
				elsif status >= 300
					body = [HTTP::STATUS_DESCRIPTIONS[status] || "Status #{status}"]
				else
					body = EMPTY_BODY
				end

				return [status, headers, body]
			end
			
			# Return nil if this controller didn't do anything. Request will keep on processing. Return a valid rack response if the controller can do so.
			def process!(request, path)
				passthrough(request, path)
			end
		end
	end
end
