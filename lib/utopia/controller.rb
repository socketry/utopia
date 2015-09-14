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

require_relative 'path'

require_relative 'middleware'
require_relative 'controller/variables'
require_relative 'controller/action'
require_relative 'controller/base'

require_relative 'controller/rewrite'

module Utopia
	class Controller
		CONTROLLER_RB = 'controller.rb'.freeze
		PATH_INFO_KEY = 'PATH_INFO'.freeze
		
		def initialize(app, options = {})
			@app = app
			@root = options[:root] || Utopia::default_root

			@controllers = {}
			
			@cache_controllers = options[:cache_controllers] || false
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
			# puts "load_controller_file(#{path.inspect}) => #{controller_path}"
			
			if File.exist?(controller_path)
				klass = Class.new(Base)
				
				# base_path is expected to be a string representing a filesystem path:
				klass.const_set(:BASE_PATH, base_path)
				
				# uri_path is expected to be an instance of Path:
				klass.const_set(:URI_PATH, uri_path)
				
				klass.const_set(:CONTROLLER, self)
				
				klass.class_eval(File.read(controller_path), controller_path)
				
				return klass.new
			else
				return nil
			end
		end
		
		def invoke_controllers(request)
			relative_path = Path[request.path_info]
			controller_path = Path.new

			while relative_path.components.any?
				controller_path.components << relative_path.components.shift
				
				if controller = lookup_controller(controller_path)
					if result = controller.process!(request, relative_path)
						return result
					end
				end
			end
			
			# The controllers may have rewriten the path so we update the path info:
			request.env[PATH_INFO_KEY] = controller_path.to_s
			
			# No controller gave a useful result:
			return nil
		end
		
		def call(env)
			variables = (env[VARIABLES_KEY] ||= Variables.new)
			
			request = Rack::Request.new(env)
			
			if result = invoke_controllers(request)
				return result
			end
			
			return @app.call(env)
		end
	end
end
