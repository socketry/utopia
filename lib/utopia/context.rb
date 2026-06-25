# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2026, by Samuel Williams.

module Utopia
	# Accessors for request-scoped Utopia state stored directly in fiber storage.
	module Context
		KEYS = {
			request: :utopia_request,
			request_path: :utopia_request_path,
			session: :utopia_session,
			variables: :utopia_variables,
			localization: :utopia_localization,
			current_locale: :utopia_current_locale,
			exception: :utopia_exception
		}.freeze
		
		def self.[] key
			Fiber[KEYS.fetch(key)]
		end
		
		def self.[]= key, value
			Fiber[KEYS.fetch(key)] = value
		end
		
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
		
		def self.clear
			KEYS.each_value do |key|
				Fiber[key] = nil
			end
		end
		
		def self.to_hash
			KEYS.transform_values{|key| Fiber[key]}
		end
		
		KEYS.each_key do |name|
			define_singleton_method(name) do
				self[name]
			end
			
			define_singleton_method("#{name}=") do |value|
				self[name] = value
			end
		end
	end
end
