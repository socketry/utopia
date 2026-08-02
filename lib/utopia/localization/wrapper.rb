# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2015-2026, by Samuel Williams.

require_relative "middleware"

module Utopia
	# A middleware which attempts to find localized content.
	module Localization
		# A wrapper to provide easy access to locale related data in the request.
		class Wrapper
			# Initialize a localization wrapper for the request.
			# @parameter request [Utopia::Request] The application request.
			def initialize(request)
				@request = request
			end
			
			# Return the localization middleware associated with the request.
			# @returns [Localization::Middleware | Nil] The current localization middleware.
			def localization
				@request.localization
			end
			
			# Check whether the request path includes a locale.
			# @returns [Boolean] Whether localization is active for the current request.
			def localized?
				localization != nil
			end
			
			# Returns the current locale or nil if not localized.
			def current_locale
				@request.locale
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
		# @parameter request [Utopia::Request] The application request.
		# @returns [Wrapper] A localization wrapper for the current request.
		def self.wrapper(request)
			Wrapper.new(request)
		end
		
		# Return a localization wrapper for the current request context.
		# @parameter request [Utopia::Request] The application request.
		# @returns [Wrapper] A localization wrapper for the current request.
		def self.[] request
			self.wrapper(request)
		end
	end
end
