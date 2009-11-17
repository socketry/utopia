
require 'utopia/middleware'
require 'utopia/path'

require 'time'

require 'mime/types'

module Utopia
	module Middleware

		class Static
			DEFAULT_TYPES = [
				"html", "css", "js", "txt", "rtf",
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
					begin
						case type
						when Array
							result["." + type[0]] = type[1]
						when String
							result["." + type] = MIME::Types.of(type).find{|mt| !mt.obsolete?}.content_type
						when Regexp
							MIME::Types[type].select{|mt| !mt.obsolete?}.each do |mt|
								extract_extensions.call(mt)
							end
						when Mime::Type
							extract_extensions.call(type)
						else
							$stderr.puts "Unable to load mime type #{type.inspect}!"
						end
					rescue
						$stderr.puts "Error while processing #{type.inspect}!"
						raise $!
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
				file = nil
				name = path.basename

				path.dirname.ascend do |parent_path|
					file_path = File.join(@root, parent_path.components, name)
					if File.exist?(file_path)
						return FileReader.new(file_path)
					end
				end

				return nil
			end

			attr :extensions

			def call(env)
				request = Rack::Request.new(env)
				ext = File.extname(request.path_info)
				if @extensions.key? ext
					file = fetch_file(Path.create(request.path_info).simplify)
					if file
						response_headers = {
							"Last-Modified" => file.mtime_date,
							"Content-Type" => @extensions[ext],
							"Content-Length" => file.size.to_s
						}

						return [200, response_headers, file]
					end
				end

				# else if no file was found:
				return @app.call(env)
			end
		end

	end
end
