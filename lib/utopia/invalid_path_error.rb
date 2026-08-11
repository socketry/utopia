# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2026, by Samuel Williams.

require "protocol/http/error"

module Utopia
	# Raised when an external request path cannot be normalized safely.
	class InvalidPathError < Protocol::HTTP::Error
		include Protocol::HTTP::BadRequest
		
		# Initialize the invalid path error.
		# @parameter path [String] The invalid request path.
		# @parameter message [String] The reason the path is invalid.
		def initialize(path, message)
			@path = path
			
			super("Invalid request path #{path.inspect}: #{message}")
		end
		
		# The invalid request path.
		attr :path
	end
end
