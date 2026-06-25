# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2014-2025, by Samuel Williams.
# Copyright, 2019, by Huba Nagy.

module Utopia
	# Session access helpers and middleware constructor.
	module Session
		CURRENT_KEY = :utopia_session
		
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
			Fiber[CURRENT_KEY]
		end
		
		# Assign the current session.
		def self.current= session
			Fiber[CURRENT_KEY] = session
		end
		
		# The current session, or raise a clear error if sessions are unavailable.
		def self.current!
			self.current or raise MissingError, "No current Utopia session!"
		end
		
		# Fetch a value from the current session.
		def self.[] key
			self.current![key]
		end
		
		# Assign a value in the current session.
		def self.[]= key, value
			self.current![key] = value
		end
		
		# Delete a value from the current session.
		def self.delete(key)
			self.current!.delete(key)
		end
	end
end
