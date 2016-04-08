# Copyright, 2012, by Samuel G. D. Williams. <http://www.codeotaku.com>
# 
# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:
# 
# The above copyright notice and this permission notice shall be included in
# all copies or substantial portions of the Software.
# 
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
# THE SOFTWARE.

require_relative 'middleware'
require_relative 'localization'

require 'time'

require 'digest/sha1'
require 'mime/types'

module Utopia
	# Serve static files and include recursive name resolution using @rel@ directory entries.
	class Static
		MIME_TYPES = {
			:xiph => {
				"ogx" => "application/ogg",
				"ogv" => "video/ogg",
				"oga" => "audio/ogg",
				"ogg" => "audio/ogg",
				"spx" => "audio/ogg",
				"flac" => "audio/flac",
				"anx" => "application/annodex",
				"axa" => "audio/annodex",
				"xspf" => "application/xspf+xml",
			},
			:media => [
				:xiph, "mp3", "mp4", "wav", "aiff", ["aac", "audio/x-aac"], "mov", "avi", "wmv", "mpg"
			],
			:text => [
				"html", "css", "js", ["map", "application/json"], "txt", "rtf", "xml", "pdf"
			],
			:fonts => [
				"otf", ["eot", "application/vnd.ms-fontobject"], "ttf", "woff"
			],
			:archive => [
				"zip", "tar", "tgz", "tar.gz", "tar.bz2", ["dmg", "application/x-apple-diskimage"],
				["torrent", "application/x-bittorrent"]
			],
			:images => [
				"png", "gif", "jpeg", "tiff", "svg"
			],
			:default => [
				:media, :text, :archive, :images, :fonts
			]
		}
		
		class MimeTypeLoader
			def initialize(library)
				@extensions = {}
				@library = library
			end
			
			attr :extensions
			
			def self.extensions_for(types, library = MIME_TYPES)
				loader = self.new(library)
				loader.expand(types)
				return loader.extensions
			end
			
			def extract_extensions(mime_types)
				mime_types.select{|mime_type| !mime_type.obsolete?}.each do |mime_type|
					mime_type.extensions.each do |ext|
						@extensions["." + ext] = mime_type.content_type
					end
				end
			end
			
			class ExpansionError < ArgumentError
			end
			
			def expand(types)
				types.each do |type|
					current_count = @extensions.size
					
					begin
						case type
						when Symbol
							self.expand(MIME_TYPES[type])
						when Array
							@extensions["." + type[0]] = type[1]
						when String
							self.extract_extensions MIME::Types.of(type)
						when Regexp
							self.extract_extensions MIME::Types[type]
						when MIME::Type
							self.extract_extensions.call([type])
						end
					rescue
						raise ExpansionError.new("#{self.class.name}: Error while processing #{type.inspect}!")
					end
					
					if @extensions.size == current_count
						raise ExpansionError.new("#{self.class.name}: Could not find any mime type for #{type.inspect}")
					end
				end
			end
		end
		
		private

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
				ranges = Rack::Utils.byte_ranges(env, size)
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
					partial_size = @range.count
					
					response[0] = 206
					response[1][CONTENT_LENGTH] = partial_size.to_s
					response[1][CONTENT_RANGE] = "bytes #{@range.min}-#{@range.max}/#{size}"
				end
				
				return response
			end
		end

		public

		DEFAULT_CACHE_CONTROL = 'public, max-age=3600'.freeze

		def initialize(app, **options)
			@app = app
			@root = (options[:root] || Utopia::default_root).freeze

			@extensions = MimeTypeLoader.extensions_for(options[:types] || MIME_TYPES[:default])

			@cache_control = (options[:cache_control] || DEFAULT_CACHE_CONTROL)
			
			self.freeze
		end

		def freeze
			@root.freeze
			@extensions.freeze
			@cache_control.freeze
			
			super
		end

		def fetch_file(path)
			# We need file_path to be an absolute path for X-Sendfile to work correctly.
			file_path = File.join(@root, path.components)
			
			if File.exist?(file_path)
				return LocalFile.new(@root, path)
			else
				return nil
			end
		end

		attr :extensions
		
		LAST_MODIFIED = 'Last-Modified'.freeze
		CONTENT_TYPE = HTTP::CONTENT_TYPE
		CACHE_CONTROL = HTTP::CACHE_CONTROL
		ETAG = 'ETag'.freeze
		ACCEPT_RANGES = 'Accept-Ranges'.freeze
		
		def call(env)
			path_info = env[Rack::PATH_INFO]
			extension = File.extname(path_info)

			if @extensions.key? extension.downcase
				path = Path[path_info].simplify
				
				if locale = env[Localization::CURRENT_LOCALE_KEY]
					path.last.insert(path.last.rindex('.') || -1, ".#{locale}")
				end
				
				if file = fetch_file(path)
					response_headers = {
						LAST_MODIFIED => file.mtime_date,
						CONTENT_TYPE => @extensions[extension],
						CACHE_CONTROL => @cache_control,
						ETAG => file.etag,
						ACCEPT_RANGES => "bytes"
					}

					if file.modified?(env)
						return file.serve(env, response_headers)
					else
						return [304, response_headers, []]
					end
				end
			end

			# else if no file was found:
			return @app.call(env)
		end
	end
end
