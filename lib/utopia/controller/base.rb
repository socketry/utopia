# frozen_string_literal: true

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
		CONTENT_TYPE = HTTP::CONTENT_TYPE
		
		# The base implementation of a controller class.
		class Base
			URI_PATH = nil
			BASE_PATH = nil
			CONTROLLER = nil
			
			# A string which is the full path to the directory which contains the controller.
			def self.base_path
				self.const_get(:BASE_PATH)
			end
			
			# A relative path to the controller directory relative to the controller root directory.
			def self.uri_path
				self.const_get(:URI_PATH)
			end
			
			# The controller middleware itself.
			def self.controller
				self.const_get(:CONTROLLER)
			end
			
			def self.inspect
				"#{super}#{self.uri_path}"
			end
			
			def self.to_s
				self.inspect
			end
			
			def to_s
				"\#<#{self.class}>"
			end
			
			def inspect
				details = self.instance_variables.map{|name| " #{name}=#{self.instance_variable_get(name)}"}
				
				"\#<#{self.class}#{details.join}>"
			end
			
			def self.freeze
				# This ensures that all class variables are frozen.
				self.instance_variables.each do |name|
					self.instance_variable_get(name).freeze
				end
				
				super
			end
			
			def self.direct?(path)
				path.dirname == uri_path
			end
			
			def catch_response
				catch(:response) do
					yield and nil
				end
			end
			
			# Return nil if this controller didn't do anything. Request will keep on processing. Return a valid rack response if the controller can do so.
			def process!(request, relative_path)
				return nil
			end

			# Copy the instance variables from the previous controller to the next controller (usually only a few). This allows controllers to share effectively the same instance variables while still being separate classes/instances.
			def copy_instance_variables(from)
				from.instance_variables.each do |name|
					self.instance_variable_set(name, from.instance_variable_get(name))
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
			
			# Respond with the response, but only if it's not nil.
			def respond?(response)
				respond!(response) if response
			end
			
			# This will cause the controller middleware to pass on the request.
			def ignore!
				throw :response, nil
			end

			# Request relative redirect. Respond with a redirect to the given target.
			def redirect!(target, status = 302)
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
			
			# Succeed the request and immediately respond.
			def succeed!(status: 200, headers: {}, type: nil, **options)
				status = HTTP::Status.new(status, 200...300)
				
				if type
					headers[CONTENT_TYPE] = type.to_s
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
		end
	end
end
