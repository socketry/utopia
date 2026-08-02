# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2014-2025, by Samuel Williams.

require_relative "../middleware"

module Utopia
	module Controller
		# Provides a stack-based instance variable lookup mechanism. It can flatten a stack of controllers into a single hash.
		class Variables
			# Initialize an empty controller stack.
			def initialize
				@controllers = []
			end
			
			# Return the innermost controller.
			# @returns [Controller::Base | Nil] The current controller.
			def top
				@controllers.last
			end
			
			# Push a controller after copying variables from the previous controller.
			# @parameter controller [Utopia::Controller::Base] The controller instance.
			# @returns [self] This variables stack.
			def << controller
				if top = self.top
					# This ensures that most variables will be at the top and controllers can naturally interactive with instance variables:
					controller.copy_instance_variables(top)
				end
				
				@controllers << controller
				
				return self
			end
			
			# We use self as a seninel
			def fetch(key, default=self)
				if controller = self.top
					if controller.instance_variables.include?(key)
						return controller.instance_variable_get(key)
					end
				end
				
				if block_given?
					yield(key)
				elsif !default.equal?(self)
					return default
				else
					raise KeyError.new(key)
				end
			end
			
			# Convert the current controller's instance variables to attributes.
			# @returns [Hash(Symbol, Object)] The current controller attributes.
			def to_hash
				attributes = {}
				
				if controller = self.top
					controller.instance_variables.each do |name|
						key = name[1..-1].to_sym
						
						attributes[key] = controller.instance_variable_get(name)
					end
				end
				
				return attributes
			end
			
			# Fetch a variable from the innermost controller.
			# @parameter key [String | Symbol] The lookup key.
			# @returns [Object | Nil] The variable value, or `nil` when it is undefined.
			def [] key
				fetch("@#{key}".to_sym, nil)
			end
		end
		
		# Fetch the controller variables associated with a request.
		# @parameter request [Rack::Request] The request.
		# @returns [Variables | Nil] The controller variables, when available.
		def self.[] request
			request.env[VARIABLES_KEY]
		end
	end
end
