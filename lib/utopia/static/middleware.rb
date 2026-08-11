# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2025-2026, by Samuel Williams.

require_relative "../middleware"
require_relative "../request"
require_relative "../response"

require_relative "local_file"
require_relative "mime_types"
require_relative "../localization/resolver"

require "traces/provider"

module Utopia
	module Static
		DEFAULT_CACHE_CONTROL = "public, max-age=3600".freeze
		
		# A middleware which serves static files from the specified root directory.
		class Middleware < Protocol::HTTP::Middleware
			include Localization::Resolver
			
			# @param root [String] The root directory to serve files from.
			# @param types [Array] The mime-types (and file extensions) to recognize/serve.
			# @param cache_control [String] The cache-control header to set for static content.
			def initialize(app, root: Utopia::default_root, types: MIME_TYPES[:default], cache_control: DEFAULT_CACHE_CONTROL)
				super(app)
				
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
			# @parameter path [Utopia::Path] The decoded path.
			# @returns [LocalFile | Nil] The local file, or `nil` when it does not exist.
			def fetch_file(path)
				url_path = Protocol::URL::Path.for(path.components)
				file_path = url_path.local_path(@root)
				
				if File.exist?(file_path)
					return LocalFile.new(@root, path, file_path)
				else
					return nil
				end
			rescue ArgumentError
				return nil
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
			# @parameter request [Utopia::Request] The request.
			# @parameter path [Protocol::URL::Path] The request path to serve.
			# @parameter extension [String] The file extension.
			# @parameter localization [Utopia::Localization::Preferences | Nil] The selected localization.
			# @returns [Protocol::HTTP::Response] The response.
			def respond(request, path, extension, localization: request.localization)
				path = Path[path]
				
				if locale = localization&.locale
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
			# @parameter request [Utopia::Request] The request.
			# @returns [Protocol::HTTP::Response] The static-file or downstream response.
			def call(request)
				path = request.url.path
				extension = File.extname(path.basename.to_s)
				
				if @extensions.key?(extension.downcase)
					response = resolve_localized(request) do |localization|
						self.respond(request, path, extension, localization: localization)
					end
					
					if response
						return response
					end
				end
				
				# else if no file was found:
				return @delegate.call(request)
			end
		end
		
		Traces::Provider(Static) do
			def respond(request, path, extension, localization: request.localization)
				attributes = {
					path: path,
					locale: localization&.locale,
				}
				
				Traces.trace("utopia.static.respond", attributes: attributes){super}
			end
		end
	end
end
