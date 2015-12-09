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
				def freeze
					# This ensures that all class variables are frozen.
					self.instance_variables.each do |name|
						self.instance_variable_get(name).freeze
					end
					
					super
				end
				
				def direct?(path)
					path.dirname == uri_path
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
				catch(:response) do
					yield and nil
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

			# Call into the next app as defined by rack.
			def call(env)
				self.class.controller.app.call(env)
			end
			
			# This will cause the middleware to generate a response.
			def respond!(response)
				throw :response, response
			end

				# This will cause the controller middleware to pass on the request.
			def ignore!
				throw :response, nil
			end

			# Request relative redirect. Respond with a redirect to the given target.
			def redirect! (target, status = 302)
				status = HTTP::Status.new(status, 300...400)
				location = target.to_s
				
				respond! [status.to_i, {HTTP::LOCATION => location}, [status.to_s]]
			end
			
			# Controller relative redirect.
			def goto!(target, status = 302)
				redirect! self.class.uri_path + target
			end
			
			# Respond with an error which indiciates some kind of failure.
			def fail!(error = 400, message = nil)
				status = HTTP::Status.new(error, 400...600)
				
				message ||= status.to_s
				respond! [status.to_i, {}, [message]]
			end
			
			def succeed!(status: 200, headers: {}, **options)
				status = HTTP::Status.new(status, 200...300)
				
				if options[:type]
					headers[Rack::CONTENT_TYPE] = options[:type].to_s
				end
				
				body = body_for(status, headers, options)
				respond! [status.to_i, headers, body || []]
			end
			
			# Generate the body for the given status, headers and options.
			def body_for(status, headers, options)
				if body = options[:body]
					return body
				elsif content = options[:content]
					return [content]
				end
			end
			
			# Legacy method name:
			alias success! succeed!
			
			# Return nil if this controller didn't do anything. Request will keep on processing. Return a valid rack response if the controller can do so.
			def process!(request, path)
				passthrough(request, path)
			end
		end
	end
end
