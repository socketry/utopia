# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2014-2025, by Samuel Williams.
# Copyright, 2019, by Huba Nagy.

require_relative "session/middleware"

module Utopia
	module Session
		def self.new(...)
			Middleware.new(...)
		end
	end
end
