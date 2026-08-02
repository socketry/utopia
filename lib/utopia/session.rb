# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2014-2025, by Samuel Williams.
# Copyright, 2019, by Huba Nagy.

require_relative "session/middleware"

module Utopia
	# Provides cookie-backed session middleware.
	module Session
		# Build session middleware around an application.
		# @parameter arguments [Array] Positional arguments forwarded to {Middleware#initialize}.
		# @parameter options [Hash] Keyword arguments forwarded to {Middleware#initialize}.
		# @returns [Middleware] The session middleware.
		def self.new(...)
			Middleware.new(...)
		end
	end
end
