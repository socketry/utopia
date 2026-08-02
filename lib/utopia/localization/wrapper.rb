# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2015-2026, by Samuel Williams.

require_relative "middleware"

module Utopia
	# A middleware which attempts to find localized content.
	module Localization
		CURRENT_KEY = :utopia_localization
		CURRENT_LOCALE_KEY = :utopia_current_locale
		
		# The current localization middleware, if localization is active.
		def self.current
			Fiber[CURRENT_KEY]
		end
		
		# Assign the current localization middleware.
		def self.current= localization
			Fiber[CURRENT_KEY] = localization
		end
		
		# The current locale, if localization is active.
		def self.current_locale
			Fiber[CURRENT_LOCALE_KEY]
		end
		
		# Assign the current locale.
		def self.current_locale= locale
			Fiber[CURRENT_LOCALE_KEY] = locale
		end
		
		# A wrapper to provide easy access to locale related data in the request.
		class Wrapper
			# Return the localization middleware active for the current request.
			# @returns [Localization::Middleware | nil] The current localization middleware.
			def localization
				Localization.current
			end
			
			# Check whether the request path includes a locale.
			# @returns [Boolean] Whether localization is active for the current request.
			def localized?
				localization != nil
			end
			
			# Returns the current locale or nil if not localized.
			def current_locale
				Localization.current_locale
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
		
		# Build a localization wrapper for the request.
		# @returns [Wrapper] A localization wrapper for the current request.
		def self.wrapper
			Wrapper.new
		end
		
		# Return a localization wrapper for the current request context.
		# @parameter request [Utopia::Request | nil] The ignored request argument.
		# @returns [Wrapper] A localization wrapper for the current request.
		def self.[] request = nil
			self.wrapper
		end
	end
end
