# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2009-2025, by Samuel Williams.

require_relative "middleware"
require_relative "localization"

require_relative "static/local_file"
require_relative "static/mime_types"

require "traces/provider"

module Utopia
	# A middleware which serves static files from the specified root directory.
	class Static
		DEFAULT_CACHE_CONTROL = "public, max-age=3600".freeze
		
		# @param root [String] The root directory to serve files from.
		# @param types [Array] The mime-types (and file extensions) to recognize/serve.
		# @param cache_control [String] The cache-control header to set for static content.
		def initialize(app, root: Utopia::default_root, types: MIME_TYPES[:default], cache_control: DEFAULT_CACHE_CONTROL)
			@app = app
			@root = root
			
			@extensions = MimeTypeLoader.extensions_for(types)
			
			@cache_control = cache_control
		end
		
		def freeze
			return self if frozen?
			
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
		
		LAST_MODIFIED = "Last-Modified".freeze
		CONTENT_TYPE = HTTP::CONTENT_TYPE
		CACHE_CONTROL = HTTP::CACHE_CONTROL
		ETAG = "ETag".freeze
		ACCEPT_RANGES = "Accept-Ranges".freeze
		
		def response_headers_for(file, content_type)
			if @cache_control.respond_to?(:call)
				cache_control = @cache_control.call(file)
			else
				cache_control = @cache_control
			end
			
			{
				LAST_MODIFIED => file.mtime_date,
				CONTENT_TYPE => content_type,
				CACHE_CONTROL => cache_control,
				ETAG => file.etag,
				ACCEPT_RANGES => "bytes"
			}
		end
		
		def respond(env, path_info, extension)
			path = Path[path_info].simplify
			
			if locale = env[Localization::CURRENT_LOCALE_KEY]
				path.last.insert(path.last.rindex(".") || -1, ".#{locale}")
			end
			
			if file = fetch_file(path)
				response_headers = self.response_headers_for(file, @extensions[extension])
				
				if file.modified?(env)
					return file.serve(env, response_headers)
				else
					return [304, response_headers, []]
				end
			end
		end
		
		def call(env)
			path_info = env[Rack::PATH_INFO]
			extension = File.extname(path_info)
			
			if @extensions.key?(extension.downcase)
				if response = self.respond(env, path_info, extension)
					return response
				end
			end
			
			# else if no file was found:
			return @app.call(env)
		end
	end
	
	Traces::Provider(Static) do
		def respond(env, path_info, extension)
			attributes = {
				path_info: path_info,
			}
			
			Traces.trace("utopia.static.respond", attributes: attributes) {super}
		end
	end
end
