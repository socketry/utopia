# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2017-2026, by Samuel Williams.

require "time"
require "digest/sha1"

require "protocol/http/body/file"
require "protocol/http/body/head"
require "protocol/http/header/range"

require_relative "../response"

module Utopia
	# A middleware which serves static files from the specified root directory.
	module Static
		# Represents a local static resource and constructs responses for it.
		class LocalFile
			# Initialize metadata for a local file.
			# @parameter path [String] The resolved filesystem path.
			def initialize(path)
				@path = path
				@stat = File.stat(@path)
				@mtime_date = @stat.mtime.httpdate
				
				fingerprint = Digest::SHA1.hexdigest("#{@stat.size}:#{@stat.mtime.to_i}:#{@stat.mtime.nsec}")
				@etag = %Q{W/"#{fingerprint}"}
			end
			
			attr :path
			attr :etag
			
			# Format the file's modification time for an HTTP header.
			# @returns [String] The HTTP-date modification time.
			def mtime_date
				@mtime_date
			end
			
			# Measure the file's content length.
			# @returns [Integer] The file size in bytes.
			def bytesize
				@stat.size
			end
			
			# Check whether the file has changed since the request validators.
			# @parameter request [Utopia::Request] The request.
			# @returns [Boolean] Whether the file is newer than the request validators.
			def modified?(request)
				if etags = request.headers["if-none-match"]
					return !etags.weak_match?(@etag)
				end
				
				if modified_since = request.headers["if-modified-since"]
					return @stat.mtime.to_i > modified_since.to_time.to_i
				end
				
				return true
			end
			
			CONTENT_LENGTH = "content-length".freeze
			CONTENT_RANGE = "content-range".freeze
			
			# Serve.
			# @parameter request [Utopia::Request] The request.
			# @parameter response_headers [Hash] The response headers.
			# @returns [Protocol::HTTP::Response] The response.
			def serve(request, response_headers)
				ranges = byte_ranges(request)
				size = bytesize
				
				# puts "Requesting ranges: #{ranges.inspect} (#{size})"
				
				if ranges == nil or ranges.size != 1
					# No ranges, or multiple ranges (which we don't support).
					# TODO: Support multiple byte-ranges, for now just send entire file:
					status = 200
					response_headers[CONTENT_LENGTH] = size.to_s
					range = nil
				else
					# Partial content:
					range = ranges[0]
					partial_size = range.size
					
					status = 206
					response_headers[CONTENT_LENGTH] = partial_size.to_s
					response_headers[CONTENT_RANGE] = "bytes #{range.min}-#{range.max}/#{size}"
				end
				
				if request.head?
					body = Protocol::HTTP::Body::Head.new(size)
				else
					body = Protocol::HTTP::Body::File.open(@path, range, size: size)
				end
				
				return Response[status, response_headers, body]
			end
			
			# Resolve satisfiable byte ranges from the parsed range header.
			# @parameter request [Utopia::Request] The request.
			# @returns [Array | Nil] The resulting values, or `nil` if the range is not applicable.
			def byte_ranges(request)
				return nil unless request.method == Protocol::HTTP::Methods::GET
				
				range = request.headers["range"]
				return nil unless range&.bytes?
				
				if validator = request.headers["if-range"]
					return nil unless if_range?(validator)
				end
				
				return range.resolve(bytesize)
			end
			
			# Check whether an If-Range validator strongly matches this file.
			# @parameter validator [String] The If-Range entity tag or HTTP date.
			# @returns [Boolean] Whether the range can be served safely.
			private def if_range?(validator)
				validator = validator.to_s
				
				# Date validators cannot be used because this file's modification date is not known to be strong:
				return false unless validator.start_with?('"')
				
				# Weak entity tags cannot authorize a partial response:
				return false if @etag.start_with?("W/")
				
				return @etag == validator
			end
		end
	end
end
