# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2017-2022, by Samuel Williams.

require 'time'
require 'digest/sha1'

module Utopia
	# A middleware which serves static files from the specified root directory.
	class Static
		# Represents a local file on disk which can be served directly, or passed upstream to sendfile.
		class LocalFile
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

			# Fit in with Rack::Sendfile
			def to_path
				full_path
			end

			def full_path
				File.join(@root, @path.components)
			end

			def mtime_date
				File.mtime(full_path).httpdate
			end

			def bytesize
				File.size(full_path)
			end

			# This reflects whether calling each would yield anything.
			def empty?
				bytesize == 0
			end

			alias size bytesize

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

			def modified?(env)
				if modified_since = env['HTTP_IF_MODIFIED_SINCE']
					return false if File.mtime(full_path) <= Time.parse(modified_since)
				end

				if etags = env['HTTP_IF_NONE_MATCH']
					etags = etags.split(/\s*,\s*/)
					return false if etags.include?(etag) || etags.include?('*')
				end

				return true
			end

			CONTENT_LENGTH = Rack::CONTENT_LENGTH
			CONTENT_RANGE = 'Content-Range'.freeze
			
			def serve(env, response_headers)
				ranges = Rack::Utils.get_byte_ranges(env['HTTP_RANGE'], size)
				response = [200, response_headers, self]

				# puts "Requesting ranges: #{ranges.inspect} (#{size})"

				if ranges == nil or ranges.size != 1
					# No ranges, or multiple ranges (which we don't support).
					# TODO: Support multiple byte-ranges, for now just send entire file:
					response[0] = 200
					response[1][CONTENT_LENGTH] = size.to_s
					@range = 0...size
				else
					# Partial content:
					@range = ranges[0]
					partial_size = @range.size
					
					response[0] = 206
					response[1][CONTENT_LENGTH] = partial_size.to_s
					response[1][CONTENT_RANGE] = "bytes #{@range.min}-#{@range.max}/#{size}"
				end
				
				return response
			end
		end
	end
end
