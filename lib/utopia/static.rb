# frozen_string_literal: true

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

require_relative 'static/local_file'
require_relative 'static/mime_types'

module Utopia
	# A middleware which serves static files from the specified root directory.
	class Static
		DEFAULT_CACHE_CONTROL = 'public, max-age=3600'.freeze

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
