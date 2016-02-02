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
require_relative 'controller/respond'

require 'concurrent/map'

module Utopia
	module Controllers
		def self.class_name_for_controller(controller)
			controller.uri_path.to_a.collect{|_| _.capitalize}.join + "_#{controller.object_id}"
		end
		
		def self.define(klass)
			self.const_set(
				class_name_for_controller(klass),
				klass,
			)
		end
	end
	
	class Controller
		CONTROLLER_RB = 'controller.rb'.freeze
		
		def initialize(app, **options)
			@app = app
			@root = options[:root] || Utopia::default_root
			
			if options[:cache_controllers]
				@controller_cache = Concurrent::Map.new
			else
				@controller_cache = nil
			end
			
			self.freeze
		end
		
		attr :app
		
		def freeze
			@root.freeze
			
			super
		end
		
		def lookup_controller(path)
			if @controller_cache
				@controller_cache.fetch_or_store(path.to_s) do
					load_controller_file(path)
				end
			else
				load_controller_file(path)
			end
		end
		
		def load_controller_file(uri_path)
			base_path = File.join(@root, uri_path.components)
			
			controller_path = File.join(base_path, CONTROLLER_RB)
			# puts "load_controller_file(#{path.inspect}) => #{controller_path}"
			
			if File.exist?(controller_path)
				klass = Class.new(Base)
				
				# base_path is expected to be a string representing a filesystem path:
				klass.const_set(:BASE_PATH, base_path.freeze)
				
				# uri_path is expected to be an instance of Path:
				klass.const_set(:URI_PATH, uri_path.dup.freeze)
				
				klass.const_set(:CONTROLLER, self)
				
				klass.class_eval(File.read(controller_path), controller_path)
				
				# Give the controller a useful name:
				# Controllers.define(klass)
				
				# We lock down the controller class to prevent unsafe modifications:
				klass.freeze
				
				# Create an instance of the controller:
				return klass.new
			else
				return nil
			end
		end
		
		def invoke_controllers(request)
			relative_path = Path[request.path_info]
			controller_path = Path.new
			variables = request.env[VARIABLES_KEY]
			
			while relative_path.components.any?
				controller_path.components << relative_path.components.shift
				
				if controller = lookup_controller(controller_path)
					# Don't modify the original controller:
					controller = controller.clone
					
					# Append the controller to the set of controller variables, updates the controller with all current instance variables.
					variables << controller
					
					if result = controller.process!(request, relative_path)
						return result
					end
				end
			end
			
			# The controllers may have rewriten the path so we update the path info:
			request.env[Rack::PATH_INFO] = controller_path.to_s
			
			# No controller gave a useful result:
			return nil
		end
		
		def call(env)
			env[VARIABLES_KEY] ||= Variables.new
			
			request = Rack::Request.new(env)
			
			if result = invoke_controllers(request)
				return result
			end
			
			return @app.call(env)
		end
	end
end
