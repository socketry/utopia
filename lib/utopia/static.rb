# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2009-2025, by Samuel Williams.

require_relative "static/middleware"

module Utopia
	module Static
		# Construct static-file middleware.
		# @returns [Static::Middleware] The static-file middleware.
		def self.new(...)
			Middleware.new(...)
		end
	end
end
