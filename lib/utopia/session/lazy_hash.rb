# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2014-2026, by Samuel Williams.

module Utopia
	module Session
		# A simple hash table which fetches it's values only when required.
		class LazyHash
			# Initialize a lazily loaded hash.
			# @yields The block which loads the initial values.
			def initialize(&block)
				@changed = false
				@values = nil
				
				@loader = block
			end
			
			# Fetch a value by key, loading the hash if necessary.
			# @parameter key [Object] The key.
			# @returns [Object | Nil] The value.
			def [] key
				load![key]
			end
			
			# Store a value by key.
			# @parameter key [Object] The key.
			# @parameter value [Object] The value.
			# @returns [Object] The stored value.
			def []= key, value
				values = load!
				
				if values[key] != value
					values[key] = value
					@changed = true
				end
				
				return value
			end
			
			# Check whether the hash contains a key.
			# @parameter key [Object] The key.
			# @returns [Boolean] Whether the key exists.
			def include?(key)
				load!.include?(key)
			end
			
			# Delete a value by key.
			# @parameter key [Object] The key.
			# @returns [Object | Nil] The deleted value.
			def delete(key)
				load!
				
				@changed = true if @values.include? key
				
				@values.delete(key)
			end
			
			# Check whether any value has changed.
			# @returns [Boolean] Whether the hash has changed.
			def changed?
				@changed
			end
			
			# Persist the session values if they have changed or require updating.
			# @parameter timeout [Numeric | Nil] The maximum age before an update is required.
			# @yields {|values, updated_at| ...} The loaded values and their update time.
			# @returns [Object | Nil] The result of the block if persistence was required.
			def persist(timeout = nil)
				return unless needs_update?(timeout)
				
				values = load!
				updated_at = values[:updated_at] = Time.now.utc
				
				result = yield(values, updated_at)
				@changed = false
				
				return result
			end
			
			# Check whether the underlying values have been loaded.
			# @returns [Boolean] Whether the values are loaded.
			def loaded?
				!@values.nil?
			end
			
			# Check whether the values should be persisted.
			# @parameter timeout [Numeric | Nil] The maximum age before an update is required.
			# @returns [Boolean] Whether an update is required.
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
			
			private
			
			# Load and return the underlying values.
			def load!
				@values ||= @loader.call
			end
		end
	end
end
