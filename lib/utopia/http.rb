# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2010-2025, by Samuel Williams.

require "http/accept"

module Utopia
	# HTTP protocol implementation.
	module HTTP
		# Pull in {::HTTP::Accept} for parsing.
		Accept = ::HTTP::Accept
		
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
		
		# A list of human readable descriptions for a given status code.
		# For a more detailed description, see https://en.wikipedia.org/wiki/List_of_HTTP_status_codes
		STATUS_DESCRIPTIONS = {
			100 => "Continue".freeze,
			101 => "Switching Protocols".freeze,
			102 => "Processing".freeze,
			103 => "Early Hints".freeze,
			200 => "OK".freeze,
			201 => "Created".freeze,
			202 => "Accepted".freeze,
			203 => "Non-Authoritative Information".freeze,
			204 => "No Content".freeze,
			205 => "Reset Content".freeze,
			206 => "Partial Content".freeze,
			207 => "Multi-Status".freeze,
			208 => "Already Reported".freeze,
			226 => "IM Used".freeze,
			300 => "Multiple Choices".freeze,
			301 => "Moved Permanently".freeze,
			302 => "Found".freeze,
			303 => "See Other".freeze,
			304 => "Not Modified".freeze,
			305 => "Use Proxy".freeze,
			307 => "Temporary Redirect".freeze,
			308 => "Permanent Redirect".freeze,
			400 => "Bad Request".freeze,
			401 => "Unauthorized".freeze,
			402 => "Payment Required".freeze,
			403 => "Forbidden".freeze,
			404 => "Not Found".freeze,
			405 => "Method Not Allowed".freeze,
			406 => "Not Acceptable".freeze,
			407 => "Proxy Authentication Required".freeze,
			408 => "Request Timeout".freeze,
			409 => "Conflict".freeze,
			410 => "Gone".freeze,
			411 => "Length Required".freeze,
			412 => "Precondition Failed".freeze,
			413 => "Content Too Large".freeze,
			414 => "URI Too Long".freeze,
			415 => "Unsupported Media Type".freeze,
			416 => "Range Not Satisfiable".freeze,
			417 => "Expectation Failed".freeze,
			418 => "I'm a Teapot".freeze,
			421 => "Misdirected Request".freeze,
			422 => "Unprocessable Content".freeze,
			423 => "Locked".freeze,
			424 => "Failed Dependency".freeze,
			425 => "Too Early".freeze,
			426 => "Upgrade Required".freeze,
			428 => "Precondition Required".freeze,
			429 => "Too Many Requests".freeze,
			431 => "Request Header Fields Too Large".freeze,
			451 => "Unavailable For Legal Reasons".freeze,
			500 => "Internal Server Error".freeze,
			501 => "Not Implemented".freeze,
			502 => "Bad Gateway".freeze,
			503 => "Service Unavailable".freeze,
			504 => "Gateway Timeout".freeze,
			505 => "HTTP Version Not Supported".freeze,
			506 => "Variant Also Negotiates".freeze,
			507 => "Insufficient Storage".freeze,
			508 => "Loop Detected".freeze,
			510 => "Not Extended".freeze,
			511 => "Network Authentication Required".freeze,
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
				STATUS_DESCRIPTIONS[@code] || @code.to_s
			end
			
			# Yield the human-readable status description.
			# @yields {|description| ...} The status description.
			# @returns [String] The yielded description.
			def each
				yield to_s
			end
		end
	end
end
