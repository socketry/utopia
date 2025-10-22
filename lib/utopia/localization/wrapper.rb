# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2009-2025, by Samuel Williams.

require_relative "middleware"

module Utopia
	# A middleware which attempts to find localized content.
	module Localization
		LOCALIZATION_KEY = "utopia.localization".freeze
		CURRENT_LOCALE_KEY = "utopia.localization.current_locale".freeze
		
		# A wrapper to provide easy access to locale related data in the request.
		class Wrapper
			def initialize(env)
				@env = env
			end
			
			def localization
				@env[LOCALIZATION_KEY]
			end
			
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
			
			def localized_path(path, locale)
				"/#{locale}#{path}"
			end
		end
		
		def self.[] request
			Wrapper.new(request.env)
		end
	end
end
