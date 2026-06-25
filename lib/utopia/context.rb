# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2026, by Samuel Williams.

module Utopia
	# Accessors for request-scoped Utopia state stored directly in fiber storage.
	module Context
		# The fiber storage keys used by Utopia.
		KEYS = {
			request: :utopia_request,
			request_path: :utopia_request_path,
			session: :utopia_session,
			variables: :utopia_variables,
			localization: :utopia_localization,
			current_locale: :utopia_current_locale,
			exception: :utopia_exception
		}.freeze
		
		# Fetch a Utopia fiber state value.
		def self.[] key
			Fiber[KEYS.fetch(key)]
		end
		
		# Assign a Utopia fiber state value.
		def self.[]= key, value
			Fiber[KEYS.fetch(key)] = value
		end
		
		# Temporarily assign Utopia fiber state values for the duration of the block.
		def self.with(**values)
			previous = {}
			
			values.each do |key, value|
				previous[key] = self[key]
				self[key] = value
			end
			
			return yield
		ensure
			previous&.each do |key, value|
				self[key] = value
			end
		end
		
		# Clear all Utopia fiber state values from the current fiber.
		def self.clear
			KEYS.each_value do |key|
				Fiber[key] = nil
			end
		end
		
		# Convert the current Utopia fiber state to a hash.
		def self.to_hash
			KEYS.transform_values{|key| Fiber[key]}
		end
		
		KEYS.each_key do |name|
			# Fetch a named Utopia fiber state value.
			define_singleton_method(name) do
				self[name]
			end
			
			# Assign a named Utopia fiber state value.
			define_singleton_method("#{name}=") do |value|
				self[name] = value
			end
		end
	end
end
