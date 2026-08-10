# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2026, by Samuel Williams.

module Utopia
	module Localization
		# Matches configured locales against language ranges.
		class Locales
			# Expand a locale into progressively less specific language ranges.
			# @parameter locale [String] The locale to expand.
			# @parameter patterns [Hash] The destination language-range mapping.
			def self.expand(locale, patterns)
				parts = locale.split("-")
				
				while parts.any?
					pattern = parts.join("-")
					patterns[pattern] ||= locale
					parts.pop
				end
			end
			
			# Initialize the configured locales.
			# @parameter names [Array(String)] The locale names, in preference order.
			def initialize(names)
				@names = names
				@patterns = {}
				
				@names.each do |name|
					self.class.expand(name, @patterns)
				end
				
				freeze
			end
			
			# Freeze this object and its internal state.
			# @returns [self] This object.
			def freeze
				return self if frozen?
				
				@names.freeze
				@patterns.freeze
				
				return super
			end
			
			attr :names
			attr :patterns
			
			# Select configured locales matching the given language ranges.
			# @parameter languages [Enumerable] Preferred language ranges.
			# @returns [Array(String)] Matching locale names in language preference order.
			def match(languages)
				languages.filter_map do |language|
					@patterns[language.name]
				end
			end
		end
	end
end
