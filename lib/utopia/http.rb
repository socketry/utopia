# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2010-2026, by Samuel Williams.

require "protocol/http/status"

module Utopia
	# HTTP protocol implementation.
	module HTTP
		# A list of commonly used HTTP status codes.
		# For help choosing the right status code, see http://racksburg.com/choosing-an-http-status-code/
		STATUS_CODES = {
			:success => 200,
			:created => 201,
			:accepted => 202,
			:moved => 301,
			:found => 302,
			:see_other => 303,
			:not_modified => 304,
			:redirect => 307,
			:bad_request => 400,
			:unauthorized => 401,
			:forbidden => 403,
			:not_found => 404,
			:not_allowed => 405,
			:unsupported_method => 405,
			:gone => 410,
			:teapot => 418,
			:unprocessible => 422, # The best status code for a client-side ArgumentError.
			:error => 500,
			:unimplemented => 501,
			:unavailable => 503
		}
		
		CONTENT_TYPE = "content-type".freeze
		LOCATION = "location".freeze
		CACHE_CONTROL = "cache-control".freeze
		
		# A small HTTP status wrapper that verifies the status code within a given range.
		class Status
			# Initialize a validated HTTP status.
			# @parameter code [Integer | Symbol] The numeric status or a key from {STATUS_CODES}.
			# @parameter valid_range [Range] The accepted numeric status range.
			# @raises [ArgumentError] If the resolved status is outside `valid_range`.
			def initialize(code, valid_range = 100...600)
				if code.is_a? Symbol
					code = STATUS_CODES[code]
				end
				
				unless valid_range.include? code
					raise ArgumentError.new("Status must be in range #{valid_range}, was given #{code}!")
				end
				
				@code = code
			end
			
			# Convert this value to an integer.
			# @returns [Integer] The numeric status code.
			def to_i
				@code
			end
			
			# Convert this object to a string.
			# @returns [String] The resulting string.
			def to_s
				return Protocol::HTTP::Status.description(@code) || @code.to_s
			end
		end
	end
end
