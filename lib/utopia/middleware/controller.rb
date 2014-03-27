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

require 'utopia/middleware'
require 'utopia/path'
require 'utopia/http'

class Rack::Request
	def controller(&block)
		if block_given?
			env["utopia.controller"].instance_eval(&block)
		else
			env["utopia.controller"]
		end
	end
end

module Utopia
	module Middleware
		class Controller
			module Direct
				def process!(path, request)
					return nil unless path.dirname == self.class.uri_path

					passthrough(path, request)
				end
			end
			
			CONTROLLER_RB = "controller.rb"

			class Variables
				def initialize
					@controllers = [Object.new]
				end

				def << controller
					@controllers << controller
				end

				def fetch(key)
					@controllers.reverse_each do |controller|
						if controller.instance_variables.include?(key)
							return controller.instance_variable_get(key)
						end
					end
					
					if block_given?
						yield key
					else
						raise KeyError.new(key)
					end
				end

				def to_hash
					attributes = {}

					@controllers.each do |controller|
						controller.instance_variables.each do |name|
							key = name[1..-1]
							
							# Instance variables that start with an underscore are considered private and not exposed:
							next if key.start_with?('_')
							
							attributes[key] = controller.instance_variable_get(name)
						end
					end

					return attributes
				end

				def [] key
					fetch("@#{key}".to_sym) { nil }
				end
				
				# Deprecated - to support old code:
				def []= key, value
					@controllers.first.instance_variable_set("@#{key}".to_sym, value)
				end
			end

			class Base
				def initialize(controller)
					@_controller = controller
					@_actions = {}

					methods.each do |method_name|
						next unless method_name.match(/on_(.*)$/)

						action($1.split("_")) do |path, request|
							# LOG.debug("Controller: #{method_name}")
							self.send(method_name, path, request)
							
							# Don't pass the result back, instead use pass! or respond!
							nil
						end
					end
				end

				def action(path, options = {}, &block)
					cur = @_actions

					path.reverse.each do |name|
						cur = cur[name] ||= {}
					end

					cur[:action] = Proc.new(&block)
				end

				def lookup(path)
					cur = @_actions

					path.components.reverse.each do |name|
						cur = cur[name]

						return nil if cur == nil

						if action = cur[:action]
							return action
						end
					end
				end

				# Given a request, call an associated action if one exists.
				def passthrough(path, request)
					action = lookup(path)

					if action
						variables = request.controller
						clone = self.dup
						
						variables << clone
						
						response = catch(:response) do
							clone.instance_exec(path, request, &action)
							
							# By default give nothing - i.e. keep on processing:
							nil
						end
						
						if response
							return clone.respond_with(*response)
						end
					end

					return nil
				end

				def call(env)
					@_controller.app.call(env)
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

					status = Utopia::HTTP::STATUS_CODES[status] || status
					headers = options[:headers] || {}

					if options[:type]
						headers['Content-Type'] ||= options[:type]
					end

					if options[:redirect]
						headers["Location"] = options[:redirect]
						status = 302 if status < 300 || status >= 400
					end

					body = []
					if options[:body]
						body = options[:body]
					elsif options[:content]
						body = [options[:content]]
					elsif status >= 300
						body = [Utopia::HTTP::STATUS_DESCRIPTIONS[status] || "Status #{status}"]
					end

					# Utopia::LOG.debug([status, headers, body].inspect)
					return [status, headers, body]
				end

				def process!(path, request)
					passthrough(path, request)
				end
				
				def self.base_path
					self.const_get(:BASE_PATH)
				end
				
				def self.uri_path
					self.const_get(:URI_PATH)
				end
				
				def self.require_local(path)
					require File.join(base_path, path)
				end
			end

			def initialize(app, options = {})
				@app = app
				@root = options[:root] || Utopia::Middleware::default_root

				@controllers = {}
				@cache_controllers = (UTOPIA_ENV == :production)

				if options[:controller_file]
					@controller_file = options[:controller_file]
				else
					@controller_file = "controller.rb"
				end
			end

			attr :app

			def lookup(path)
				if @cache_controllers
					return @controllers.fetch(path.to_s) do |key|
						@controllers[key] = load_file(path)
					end
				else
					return load_file(path)
				end
			end

			def load_file(path)
				if path.directory?
					uri_path = path
					base_path = File.join(@root, uri_path.components)
				else
					uri_path = path.dirname
					base_path = File.join(@root, uri_path.components)
				end

				controller_path = File.join(base_path, CONTROLLER_RB)

				if File.exist?(controller_path)
					klass = Class.new(Base)
					klass.const_set(:BASE_PATH, base_path)
					klass.const_set(:URI_PATH, uri_path)
					
					$LOAD_PATH.unshift(base_path)
					
					klass.class_eval(File.read(controller_path), controller_path)
					
					$LOAD_PATH.delete(base_path)
					
					return klass.new(self)
				else
					return nil
				end
			end

			def fetch_controllers(path)
				controllers = []

				path.ascend do |parent_path|
					controllers << lookup(parent_path)
				end

				return controllers.compact.reverse
			end

			def call(env)
				variables = (env["utopia.controller"] ||= Variables.new)
				
				request = Rack::Request.new(env)

				path = Path.create(request.path_info)
				fetch_controllers(path).each do |controller|
					if result = controller.process!(path, request)
						return result
					end
				end

				return @app.call(env)
			end
		end

	end
end
