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
			def localization
				Localization.current
			end
			
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
			
			def localized_path(path, locale)
				"/#{locale}#{path}"
			end
		end
		
		def self.wrapper
			Wrapper.new
		end
		
		def self.[] request = nil
			self.wrapper
		end
	end
end
