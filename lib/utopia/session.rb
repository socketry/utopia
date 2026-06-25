# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2014-2025, by Samuel Williams.
# Copyright, 2019, by Huba Nagy.

require_relative "context"

module Utopia
	# Session access helpers and middleware constructor.
	module Session
		# Base class for Utopia session errors.
		class Error < StandardError
		end
		
		# Raised when session access requires installed session middleware.
		class MissingError < Error
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
		
		# The current session, if session middleware is installed.
		def self.current
			Context.session
		end
		
		# The current session, or raise a clear error if sessions are unavailable.
		def self.required
			self.current or raise MissingError, "No current Utopia session!"
		end
		
		# Fetch a value from the current session.
		def self.[] key
			self.required[key]
		end
		
		# Assign a value in the current session.
		def self.[]= key, value
			self.required[key] = value
		end
		
		# Delete a value from the current session.
		def self.delete(key)
			self.required.delete(key)
		end
	end
end
