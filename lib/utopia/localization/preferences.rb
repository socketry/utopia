# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2026, by Samuel Williams.

module Utopia
	module Localization
		# Immutable localization preferences for a request or resolved resource.
		class Preferences
			# Initialize localization preferences.
			# @parameter all_locales [Array(String)] All configured locales.
			# @parameter preferred_locales [Array(String | Nil)] Locales in resolution order.
			# @parameter default_locale [String | Nil] The configured default locale.
			# @parameter locale [String | Nil] The currently selected locale.
			def initialize(all_locales:, preferred_locales:, default_locale:, locale: preferred_locales.first)
				@all_locales = all_locales
				@preferred_locales = preferred_locales
				@default_locale = default_locale
				@locale = locale
				
				freeze
			end
			
			# Freeze this object and its internal state.
			# @returns [self] This object.
			def freeze
				return self if frozen?
				
				@all_locales.each(&:freeze)
				@preferred_locales.each(&:freeze)
				@default_locale.freeze
				@locale.freeze
				
				@all_locales.freeze
				@preferred_locales.freeze
				
				return super
			end
			
			attr :all_locales
			attr :preferred_locales
			attr :default_locale
			attr :locale
			
			# Whether localization is active.
			# @returns [Boolean] `true` when locales are configured.
			def localized?
				!@all_locales.empty?
			end
			
			# Build a path with the given locale prefix.
			# @parameter path [Utopia::Path | String] The path.
			# @parameter locale [String | Nil] The locale.
			# @returns [String] The locale-prefixed path.
			def localized_path(path, locale = @locale)
				if locale
					return "/#{locale}#{path}"
				else
					return path.to_s
				end
			end
			
			# Select a locale without changing the original preferences.
			# @parameter locale [String | Nil] The selected locale.
			# @returns [Preferences] A new localization preference object.
			def with(locale:)
				self.class.new(
					all_locales: @all_locales,
					preferred_locales: @preferred_locales,
					default_locale: @default_locale,
					locale: locale,
				)
			end
		end
	end
end
