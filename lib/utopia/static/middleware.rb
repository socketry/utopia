# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2025-2026, by Samuel Williams.

require_relative "../middleware"
require_relative "../localization"
require_relative "../request"
require_relative "../response"

require_relative "local_file"
require_relative "mime_types"

require "traces/provider"

module Utopia
	module Static
		DEFAULT_CACHE_CONTROL = "public, max-age=3600".freeze
		
		# A middleware which serves static files from the specified root directory.
		class Middleware
			# @param root [String] The root directory to serve files from.
			# @param types [Array] The mime-types (and file extensions) to recognize/serve.
			# @param cache_control [String] The cache-control header to set for static content.
			def initialize(app, root: Utopia::default_root, types: MIME_TYPES[:default], cache_control: DEFAULT_CACHE_CONTROL)
				@app = app
				@root = root
				
				@extensions = MimeTypeLoader.extensions_for(types)
				
				@cache_control = cache_control
			end
			
			# Freeze this object and its internal state.
			# @returns [self] This object.
			def freeze
				return self if frozen?
				
				@root.freeze
				@extensions.freeze
				@cache_control.freeze
				
				super
			end
			
			# Open metadata for an existing file under the static root.
			# @parameter path [Utopia::Path | String] The path.
			# @returns [LocalFile | nil] The local file, or `nil` when it does not exist.
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
			
			LAST_MODIFIED = "last-modified".freeze
			CONTENT_TYPE = HTTP::CONTENT_TYPE
			CACHE_CONTROL = HTTP::CACHE_CONTROL
			ETAG = "etag".freeze
			ACCEPT_RANGES = "accept-ranges".freeze
			
			# Build response headers for the given file.
			# @parameter file [LocalFile] The file.
			# @parameter content_type [String] The content type.
			# @returns [Hash(String, String)] The response headers.
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
			
			# Respond.
			# @parameter request [Protocol::HTTP::Request] The request.
			# @parameter path_info [String] The request path to serve.
			# @parameter extension [String] The file extension.
			# @returns [Protocol::HTTP::Response] The response.
			def respond(request, path_info, extension)
				path = Path[path_info].simplify
				
				if locale = Localization.current_locale
					path.last.insert(path.last.rindex(".") || -1, ".#{locale}")
				end
				
				if file = fetch_file(path)
					response_headers = self.response_headers_for(file, @extensions[extension])
					
					if file.modified?(request)
						return file.serve(request, response_headers)
					else
						return Response[304, response_headers, []]
					end
				end
			end
			
			# Serve a recognized static file or pass the request to the next middleware.
			# @parameter request [Protocol::HTTP::Request] The request.
			# @returns [Protocol::HTTP::Response] The static-file or downstream response.
			def call(request)
				path_info = Utopia::Request.current!.path_info
				extension = File.extname(path_info)
				
				if @extensions.key?(extension.downcase)
					if response = self.respond(request, path_info, extension)
						return response
					end
				end
				
				# else if no file was found:
				return @app.call(request)
			end
		end
		
		Traces::Provider(Static) do
			def respond(request, path_info, extension)
				attributes = {
					path_info: path_info,
				}
				
				Traces.trace("utopia.static.respond", attributes: attributes){super}
			end
		end
	end
end
