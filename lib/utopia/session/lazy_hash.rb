# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2014-2026, by Samuel Williams.

module Utopia
	module Session
		# A simple hash table which fetches it's values only when required.
		class LazyHash
			# Base class for session mutation errors.
			class MutationError < Session::Error
			end
			
			# Raised when mutating a session after it has been committed.
			class AlreadyCommittedError < MutationError
			end
			
			# Raised when mutating a session from a non-owning fiber.
			class WrongFiberError < MutationError
			end
			
			# Initialize a lazy hash with a block for loading values.
			def initialize(&block)
				@changed = false
				@values = nil
				@owner = Fiber.current
				@committed = false
				
				@loader = block
			end
			
			# The loaded session values, if already loaded.
			attr :values
			
			# The fiber which owns session mutation.
			attr :owner
			
			# Fetch a session value.
			def [] key
				load![key]
			end
			
			# Assign a session value.
			def []= key, value
				check_mutable!
				
				values = load!
				
				if values[key] != value
					values[key] = value
					@changed = true
				end
				
				return value
			end
			
			# Check whether the session includes the specified key.
			def include?(key)
				load!.include?(key)
			end
			
			# Delete a session value.
			def delete(key)
				check_mutable!
				load!
				
				@changed = true if @values.include? key
				
				@values.delete(key)
			end
			
			# Whether the session has changed since it was loaded.
			def changed?
				@changed
			end
			
			# Whether the session has already been committed.
			def committed?
				@committed
			end
			
			# Mark the session as committed.
			def commit!
				check_owner!
				@committed = true
			end
			
			# Load the session values if they have not been loaded yet.
			def load!
				@values ||= @loader.call
			end
			
			# Whether the session values have been loaded.
			def loaded?
				!@values.nil?
			end
			
			# Whether the session should be committed to the response.
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
			
			def check_mutable!
				check_owner!
				
				if @committed
					raise AlreadyCommittedError, "Cannot mutate a committed session!"
				end
			end
			
			def check_owner!
				unless Fiber.current.equal?(@owner)
					raise WrongFiberError, "Cannot mutate session from a different fiber!"
				end
			end
		end
	end
end
