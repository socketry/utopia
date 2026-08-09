# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2009-2025, by Samuel Williams.

require_relative "localization/preferences"
require_relative "localization/resolver"
require_relative "localization/middleware"

module Utopia
	# Computes request localization preferences and resolves localized resources.
	module Localization
		# Construct localization middleware.
		# @returns [Localization::Middleware] The localization middleware.
		def self.new(...)
			Middleware.new(...)
		end
	end
end
