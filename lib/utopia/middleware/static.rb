
require 'utopia/middleware'
require 'utopia/path'

require 'time'

require 'mime/types'

module Utopia
	module Middleware

		class Static
			DEFAULT_TYPES = [
				"html", "css", "js", "txt", "rtf", "xml",
				"pdf", "zip", "tar", "tgz", "tar.gz", "tar.bz2", "dmg",
				"mp3", "mp4", "wav", "aiff", ["aac", "audio/x-aac"], "mov", "avi", "wmv",
				/^image/
			]

			private

			class FileReader
				def initialize(path)
					@path = path
				end

				attr :path

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
			end

			def load_mime_types(types)
				result = {}

				extract_extensions = lambda do |mime_type|
					mime_type.extensions.each{|ext| result["." + ext] = mime_type.content_type}
				end

				types.each do |type|
					current_count = result.size
					
					begin
						case type
						when :defaults
							result = load_mime_types(DEFAULT_TYPES).merge(result)
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
						LOG.warn "#{self.class.name}: Could not find any mime type for file extension #{type.inspect}"
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
					@extensions = load_mime_types(DEFAULT_TYPES)
				end
				
				LOG.info "#{self.class.name}: Running in #{@root} with #{extensions.size} filetypes"
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
				if @extensions.key? ext
					path = Path.create(request.path_info).simplify
					
					if file = fetch_file(path)
						response_headers = {
							"Last-Modified" => file.mtime_date,
							"Content-Type" => @extensions[ext],
							"Content-Length" => file.size.to_s
						}

						return [200, response_headers, file]
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
