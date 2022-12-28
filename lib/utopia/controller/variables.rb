# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2014-2020, by Samuel Williams.

module Utopia
	class Controller
		# Provides a stack-based instance variable lookup mechanism. It can flatten a stack of controllers into a single hash.
		class Variables
			def initialize
				@controllers = []
			end
			
			def top
				@controllers.last
			end

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

			def [] key
				fetch("@#{key}".to_sym, nil)
			end
		end
	end
end
