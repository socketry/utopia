# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2009-2025, by Samuel Williams.

require_relative "localization/middleware"

module Utopia
	module Localization
		def self.new(...)
			Middleware.new(...)
		end
	end
end
