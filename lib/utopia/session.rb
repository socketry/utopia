# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2014-2025, by Samuel Williams.
# Copyright, 2019, by Huba Nagy.

module Utopia
	# Session middleware constructor and types.
	module Session
		# Base class for Utopia session errors.
		class Error < StandardError
		end
	end
end

require_relative "session/middleware"

module Utopia
	module Session
		# Build a session middleware instance.
		def self.new(...)
			Middleware.new(...)
		end
		
	end
end
