# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2009-2020, by Samuel Williams.
# Copyright, 2009, by System Administrator.

require_relative 'path'

require_relative 'middleware'
require_relative 'controller/variables'
require_relative 'controller/base'

require_relative 'controller/rewrite'
require_relative 'controller/respond'
require_relative 'controller/actions'

require 'concurrent/map'

module Utopia
	# A middleware which loads controller classes and invokes functionality based on the requested path.
	class Controller
		# The controller filename.
		CONTROLLER_RB = 'controller.rb'.freeze
		
		def self.[] request
			request.env[VARIABLES_KEY]
		end
		
		# @param root [String] The content root where controllers will be loaded from.
		# @param base [Class] The base class for controllers.
		def initialize(app, root: Utopia::default_root, base: Controller::Base)
			@app = app
			@root = root
			
			@controller_cache = Concurrent::Map.new
			
			@base = base
		end
		
		attr :app
		
		def freeze
			return self if frozen?
			
			@root.freeze
			@base.freeze
			
			super
		end
		
		# Fetch the controller for the given relative path. May be cached.
		def lookup_controller(path)
			@controller_cache.fetch_or_store(path.to_s) do
				load_controller_file(path)
			end
		end
		
		# Loads the controller file for the given relative url_path.
		def load_controller_file(uri_path)
			base_path = File.join(@root, uri_path.components)
			
			controller_path = File.join(base_path, CONTROLLER_RB)
			# puts "load_controller_file(#{path.inspect}) => #{controller_path}"
			
			if File.exist?(controller_path)
				klass = Class.new(@base)
				
				# base_path is expected to be a string representing a filesystem path:
				klass.const_set(:BASE_PATH, base_path.freeze)
				
				# uri_path is expected to be an instance of Path:
				klass.const_set(:URI_PATH, uri_path.dup.freeze)
				
				klass.const_set(:CONTROLLER, self)
				
				klass.class_eval(File.read(controller_path), controller_path)
				
				# We lock down the controller class to prevent unsafe modifications:
				klass.freeze
				
				# Create an instance of the controller:
				return klass.new
			else
				return nil
			end
		end
		
		# Invoke the controller layer for a given request. The request path may be rewritten.
		def invoke_controllers(request)
			request_path = Path.from_string(request.path_info)
			
			# The request path must be absolute. We could handle this internally but it is probably better for this to be an error:
			raise ArgumentError.new("Invalid request path #{request_path}") unless request_path.absolute?
			
			# The controller path contains the current complete path being evaluated:
			controller_path = Path.new
			
			# Controller instance variables which eventually get processed by the view:
			variables = request.env[VARIABLES_KEY]
			
			while request_path.components.any?
				# We copy one path component from the relative path to the controller path at a time. The controller, when invoked, can modify the relative path (by assigning to relative_path.components). This allows for controller-relative rewrites, but only the remaining path postfix can be modified.
				controller_path.components << request_path.components.shift
				
				if controller = lookup_controller(controller_path)
					# Don't modify the original controller:
					controller = controller.clone
					
					# Append the controller to the set of controller variables, updates the controller with all current instance variables.
					variables << controller
					
					if result = controller.process!(request, request_path)
						return result
					end
				end
			end
			
			# Controllers can directly modify relative_path, which is copied into controller_path. The controllers may have rewriten the path so we update the path info:
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
