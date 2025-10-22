# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2014-2022, by Samuel Williams.

module Utopia
	module Session
		# A simple hash table which fetches it's values only when required.
		class LazyHash
			def initialize(&block)
				@changed = false
				@values = nil
				
				@loader = block
			end
			
			attr :values
			
			def [] key
				load![key]
			end
			
			def []= key, value
				values = load!
				
				if values[key] != value
					values[key] = value
					@changed = true
				end
				
				return value
			end
			
			def include?(key)
				load!.include?(key)
			end
			
			def delete(key)
				load!
				
				@changed = true if @values.include? key
				
				@values.delete(key)
			end
			
			def changed?
				@changed
			end
			
			def load!
				@values ||= @loader.call
			end
			
			def loaded?
				!@values.nil?
			end
			
			def needs_update?(timeout = nil)
				# If data has changed, we need update:
				return true if @changed
				
				# We want to be careful here and not call load! which isn't cheap operation.
				if timeout and @values and updated_at = @values[:updated_at]
					# If the last update was too long ago, we need update:
					return true if updated_at < (Time.now - timeout)
				end
				
				return false
			end
		end
	end
end
