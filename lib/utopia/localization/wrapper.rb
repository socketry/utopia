# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2015-2026, by Samuel Williams.

require_relative "middleware"

module Utopia
	# A middleware which attempts to find localized content.
	module Localization
		LOCALIZATION_KEY = "utopia.localization".freeze
		CURRENT_LOCALE_KEY = "utopia.localization.current_locale".freeze
		
		# A wrapper to provide easy access to locale related data in the request.
		class Wrapper
			# Initialize a localization wrapper for a Rack environment.
			# @parameter env [Hash] The Rack environment.
			def initialize(env)
				@env = env
			end
			
			# Fetch the localization middleware associated with this request.
			# @returns [Middleware | Nil] The localization middleware, when active.
			def localization
				@env[LOCALIZATION_KEY]
			end
			
			# Check whether the request path includes a locale.
			# @returns [Boolean] Whether localization is active for the current request.
			def localized?
				localization != nil
			end
			
			# Returns the current locale or nil if not localized.
			def current_locale
				@env[CURRENT_LOCALE_KEY]
			end
			
			# Returns the default locale or nil if not localized.
			def default_locale
				localization && localization.default_locale
			end
			
			# Returns an empty array if not localized.
			def all_locales
				localization && localization.all_locales || []
			end
			
			# Build a path with the selected locale.
			# @parameter path [Utopia::Path | String] The path.
			# @parameter locale [String] The locale.
			# @returns [String] The locale-prefixed path.
			def localized_path(path, locale)
				"/#{locale}#{path}"
			end
		end
		
		# Build a localization wrapper for a request.
		# @parameter request [Rack::Request] The request.
		# @returns [Wrapper] The localization wrapper.
		def self.[] request
			Wrapper.new(request.env)
		end
	end
end
