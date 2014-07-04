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

require_relative 'controller/variables'
require_relative 'controller/action'
require_relative 'controller/base'

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
			CONTROLLER_RB = "controller.rb".freeze

			def initialize(app, options = {})
				@app = app
				@root = options[:root] || Utopia::Middleware::default_root

				@controllers = {}
				@cache_controllers = (UTOPIA_ENV == :production)
			end
			
			attr :app
			
			def lookup_controller(path)
				if @cache_controllers
					return @controllers.fetch(path.to_s) do |key|
						@controllers[key] = load_controller_file(path)
					end
				else
					return load_controller_file(path)
				end
			end
			
			def load_controller_file(path)
				uri_path = path
				base_path = File.join(@root, uri_path.components)
				
				controller_path = File.join(base_path, CONTROLLER_RB)
				puts "load_controller_file(#{path.inspect}) => #{controller_path}"
				
				if File.exist?(controller_path)
					klass = Class.new(Base)
					klass.const_set(:BASE_PATH, base_path)
					klass.const_set(:URI_PATH, uri_path)
					klass.const_set(:CONTROLLER, self)
					
					$LOAD_PATH.unshift(base_path)
					
					klass.class_eval(File.read(controller_path), controller_path)
					
					$LOAD_PATH.delete(base_path)
					
					return klass.new
				else
					return nil
				end
			end
			
			def invoke_controllers(variables, request, done = Set.new)
				path = Path.create(request.path_info)
				controller_path = Path.new
				
				path.descend do |controller_path|
					puts "Invoke controller: #{controller_path}"
					if controller = lookup_controller(controller_path)
						# We only want to invoke controllers which have not already been invoked:
						unless done.include? controller
							# If we get throw :rewrite, location, the URL has been rewritten and we need to request again:
							location = catch(:rewrite) do
								# Invoke the controller and if it returns a result, send it back out:
								if result = controller.process!(request, path)
									return result
								end
							end
							
							if location
								request.env['PATH_INFO'] = location.to_s
								
								return invoke_controllers(variables, request, done)
							end
							
							done << controller
						end
					end
				end
				
				# No controller gave a useful result:
				return nil
			end
			
			def call(env)
				variables = (env["utopia.controller"] ||= Variables.new)
				
				request = Rack::Request.new(env)
				
				if result = invoke_controllers(variables, request)
					return result
				end
				
				return @app.call(env)
			end
		end
	end
end
