# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2017-2025, by Samuel Williams.

require "time"
require "digest/sha1"

require_relative "../response"

module Utopia
	# A middleware which serves static files from the specified root directory.
	module Static
		# Represents a local file on disk which can be served directly, or passed upstream to sendfile.
		class LocalFile
			# Initialize metadata for a file beneath a static root.
			# @parameter root [String] The root directory.
			# @parameter path [Utopia::Path | String] The path.
			def initialize(root, path)
				@root = root
				@path = path
				@etag = Digest::SHA1.hexdigest("#{File.size(full_path)}#{mtime_date}")
				
				@range = nil
			end
			
			attr :root
			attr :path
			attr :etag
			attr :range
			
			# Expose the filesystem path for upstream sendfile support.
			def to_path
				full_path
			end
			
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
			
			# This reflects whether calling each would yield anything.
			def empty?
				bytesize == 0
			end
			
			alias size bytesize
			
			# Enumerate the contained values.
			# @returns [Enumerator] An enumerator over the resulting values.
			def each
				File.open(full_path, "rb") do |file|
					file.seek(@range.begin)
					remaining = @range.end - @range.begin+1
					
					while remaining > 0
						break unless part = file.read([8192, remaining].min)
						
						remaining -= part.length
						
						yield part
					end
				end
			end
			
			# Check whether the file has changed since the request validators.
			# @parameter request [Protocol::HTTP::Request] The request.
			# @returns [Boolean] Whether the file is newer than the request validators.
			def modified?(request)
				if modified_since = request.headers["if-modified-since"]
					return false if File.mtime(full_path) <= Time.parse(modified_since)
				end
				
				if etags = request.headers["if-none-match"]
					etags = etags.split(/\s*,\s*/)
					return false if etags.include?(etag) || etags.include?("*")
				end
				
				return true
			end
			
			CONTENT_LENGTH = "content-length".freeze
			CONTENT_RANGE = "content-range".freeze
			
			# Serve.
			# @parameter request [Protocol::HTTP::Request] The request.
			# @parameter response_headers [Hash] The response headers.
			# @returns [Protocol::HTTP::Response] The response.
			def serve(request, response_headers)
				ranges = byte_ranges(request.headers["range"])
				
				# puts "Requesting ranges: #{ranges.inspect} (#{size})"
				
				if ranges == nil or ranges.size != 1
					# No ranges, or multiple ranges (which we don't support).
					# TODO: Support multiple byte-ranges, for now just send entire file:
					status = 200
					response_headers[CONTENT_LENGTH] = size.to_s
					@range = 0...size
				else
					# Partial content:
					@range = ranges[0]
					partial_size = @range.size
					
					status = 206
					response_headers[CONTENT_LENGTH] = partial_size.to_s
					response_headers[CONTENT_RANGE] = "bytes #{@range.min}-#{@range.max}/#{size}"
				end
				
				return Response[status, response_headers, self]
			end
			
			# Parse satisfiable byte ranges from the request header.
			# @parameter header [String] The header value.
			# @returns [Array] The resulting values.
			def byte_ranges(header)
				return nil unless header
				
				units, ranges = header.split("=", 2)
				return nil unless units == "bytes" && ranges
				
				ranges.split(/\s*,\s*/).map do |range|
					first, last = range.split("-", 2)
					
					if first.empty?
						length = Integer(last)
						(size - length)...size
					else
						first = Integer(first)
						last = last.empty? ? size - 1 : Integer(last)
						first..last
					end
				end
			rescue ArgumentError
				nil
			end
		end
	end
end
