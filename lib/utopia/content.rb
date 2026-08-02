# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2009-2025, by Samuel Williams.

require_relative "content/middleware"

module Utopia
	module Content
		def self.new(...)
			Middleware.new(...)
		end
	end
end
