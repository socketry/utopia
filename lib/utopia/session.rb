# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2014-2025, by Samuel Williams.
# Copyright, 2019, by Huba Nagy.

require_relative "context"

module Utopia
	module Session
		class Error < StandardError
		end
		
		class MissingError < Error
		end
	end
end

require_relative "session/middleware"

module Utopia
	module Session
		
		def self.new(...)
			Middleware.new(...)
		end
		
		def self.current
			Context.session
		end
		
		def self.required
			self.current or raise MissingError, "No current Utopia session!"
		end
		
		def self.[] key
			self.required[key]
		end
		
		def self.[]= key, value
			self.required[key] = value
		end
		
		def self.delete(key)
			self.required.delete(key)
		end
	end
end
