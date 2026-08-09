# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2017-2025, by Samuel Williams.

require "time"
require "digest/sha1"

require "protocol/http/body/file"
require "protocol/http/header/range"

require_relative "../response"

module Utopia
	# A middleware which serves static files from the specified root directory.
	module Static
		# Represents a local static resource and constructs responses for it.
		class LocalFile
			# Initialize metadata for a file beneath a static root.
			# @parameter root [String] The root directory.
			# @parameter path [Utopia::Path | String] The path.
			def initialize(root, path)
				@root = root
				@path = path
				fingerprint = Digest::SHA1.hexdigest("#{File.size(full_path)}#{mtime_date}")
				@etag = %Q{"#{fingerprint}"}
			end
			
			attr :root
			attr :path
			attr :etag
			
			# Resolve this file beneath its configured root.
			# @returns [String] The full filesystem path.
			def full_path
				File.join(@root, @path.components)
			end
			
			# Format the file's modification time for an HTTP header.
			# @returns [String] The HTTP-date modification time.
			def mtime_date
				File.mtime(full_path).httpdate
			end
			
			# Measure the file's content length.
			# @returns [Integer] The file size in bytes.
			def bytesize
				File.size(full_path)
			end
			
			# Check whether the file has changed since the request validators.
			# @parameter request [Utopia::Request] The request.
			# @returns [Boolean] Whether the file is newer than the request validators.
			def modified?(request)
				if etags = request.headers["if-none-match"]
					return !etags.weak_match?(@etag)
				end
				
				if modified_since = request.headers["if-modified-since"]
					return File.mtime(full_path).to_i > modified_since.to_time.to_i
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
				ranges = byte_ranges(request.headers["range"])
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
				
				body = Protocol::HTTP::Body::File.open(full_path, range, size: size)
				
				return Response[status, response_headers, body]
			end
			
			# Resolve satisfiable byte ranges from the parsed range header.
			# @parameter range [Protocol::HTTP::Header::Range | Nil] The parsed range header.
			# @returns [Array | Nil] The resulting values, or `nil` if the range is not applicable.
			def byte_ranges(range)
				return nil unless range&.bytes?
				
				return range.resolve(bytesize)
			end
		end
	end
end
