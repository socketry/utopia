#	This file is part of the "Utopia Framework" project, and is licensed under the GNU AGPLv3.
#	Copyright 2010 Samuel Williams. All rights reserved.
#	See <utopia.rb> for licensing details.
require 'utopia/middleware'
require 'utopia/path'

require 'time'

require 'digest/sha1'
require 'mime/types'

module Utopia
	module Middleware

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
					"html", "css", "js", "txt", "rtf", "xml", "pdf"
				],
				:archive => [
					"zip", "tar", "tgz", "tar.gz", "tar.bz2", ["dmg", "application/x-apple-diskimage"]
				],
				:images => [
					"png", "gif", "jpeg", "tiff"
				],
				:default => [
					:media, :text, :archive, :images
				]
			}

			private

			class FileReader
				def initialize(path)
					@path = path
					@etag = Digest::SHA1.hexdigest("#{File.size(@path)}#{mtime_date}")
				end

				attr :path
				attr :etag

				def to_path
					@path
				end

				def mtime_date
					File.mtime(@path).httpdate
				end

				def size
					File.size(@path)
				end

				def each
					File.open(@path, "rb") do |fp|
						while part = fp.read(8192)
							yield part
						end
					end
				end

				def modified?(env)
					if modified_since = env['HTTP_IF_MODIFIED_SINCE']
						return false if File.mtime(@path) <= Time.parse(modified_since)
					end

					if etags = env['HTTP_IF_NONE_MATCH']
						etags = etags.split(/\s*,\s*/)
						return false if etags.include?(etag) || etags.include?('*')
					end

					return true
				end
			end

			def load_mime_types(types)
				result = {}

				extract_extensions = lambda do |mime_type|
					# LOG.info "Extracting #{mime_type.inspect}"
					mime_type.extensions.each{|ext| result["." + ext] = mime_type.content_type}
				end

				types.each do |type|
					current_count = result.size
					# LOG.info "Processing #{type.inspect}"
					
					begin
						case type
						when Symbol
							result = load_mime_types(MIME_TYPES[type]).merge(result)
						when Array
							result["." + type[0]] = type[1]
						when String
							mt = MIME::Types.of(type).select{|mt| !mt.obsolete?}.each do |mt|
								extract_extensions.call(mt)
							end
						when Regexp
							MIME::Types[type].select{|mt| !mt.obsolete?}.each do |mt|
								extract_extensions.call(mt)
							end
						when MIME::Type
							extract_extensions.call(type)
						end
					rescue
						LOG.error "#{self.class.name}: Error while processing #{type.inspect}!"
						raise $!
					end
					
					if result.size == current_count
						LOG.warn "#{self.class.name}: Could not find any mime type for #{type.inspect}"
					end
				end

				return result
			end

			public
			def initialize(app, options = {})
				@app = app
				@root = options[:root] || Utopia::Middleware::default_root

				if options[:types]
					@extensions = load_mime_types(options[:types])
				else
					@extensions = load_mime_types(MIME_TYPES[:default])
				end
				
				@cache_control = options[:cache_control] || "public, max-age=3600"
				
				LOG.info "** #{self.class.name}: Running in #{@root} with #{extensions.size} filetypes"
				# LOG.info @extensions.inspect
			end

			def fetch_file(path)
				file_path = File.join(@root, path.components)
				if File.exist?(file_path)
					return FileReader.new(file_path)
				else
					return nil
				end
			end

			def lookup_relative_file(path)
				file = nil
				name = path.basename

				if split = path.split("@rel@")
					path = split[0]
					name = split[1].components
					
					# Fix a problem if the browser request has multiple @rel@
					# This normally indicates a browser bug.. :(
					name.delete("@rel@")
				else
					path = path.dirname
					
					# Relative lookups are not done unless explicitly required by @rel@
					# ... but they do work. This is a performance optimization.
					return nil
				end

				# LOG.debug("Searching for #{name.inspect} starting in #{path.components}")

				path.ascend do |parent_path|
					file_path = File.join(@root, parent_path.components, name)
					# LOG.debug("File path: #{file_path}")
					if File.exist?(file_path)
						return (parent_path + name).to_s
					end
				end

				return nil
			end

			attr :extensions

			def call(env)
				request = Rack::Request.new(env)
				ext = File.extname(request.path_info)
				if @extensions.key? ext.downcase
					path = Path.create(request.path_info).simplify
					
					if file = fetch_file(path)
						response_headers = {
							"Last-Modified" => file.mtime_date,
							"Content-Type" => @extensions[ext],
							"Cache-Control" => @cache_control,
							"ETag" => file.etag
						}

						if file.modified?(env)
							response_headers["Content-Length"] = file.size.to_s
							return [200, response_headers, file]
						else
							return [304, response_headers, []]
						end
					elsif redirect = lookup_relative_file(path)
						return [307, {"Location" => redirect}, []]
					end
				end

				# else if no file was found:
				return @app.call(env)
			end
		end

	end
end
