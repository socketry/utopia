# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2026, by Samuel Williams.

require "tempfile"
require "stringio"

require "protocol/http/request"
require "protocol/multipart/form_data"
require "protocol/url/form_data/parser"

module Utopia
	# Utopia's application-facing request wrapper.
	#
	# Protocol request methods are delegated to the underlying request; parsing
	# and application conveniences live here rather than on protocol-http itself.
	class Request
		FORM_DATA_UNDEFINED = Object.new.freeze
		private_constant :FORM_DATA_UNDEFINED
		
		# A file uploaded as part of a multipart form.
		class Upload
			# Initialize an uploaded file.
			# @parameter headers [Hash] The multipart part headers.
			# @parameter filename [String] The submitted filename.
			# @parameter tempfile [Tempfile] The temporary file containing the uploaded data.
			# @parameter size [Integer] The size of the uploaded data in bytes.
			def initialize(headers, filename, tempfile, size)
				@headers = headers
				@filename = filename
				@tempfile = tempfile
				@size = size
			end
			
			# The multipart part headers.
			attr :headers
			
			# The submitted filename.
			attr :filename
			
			# The temporary file containing the uploaded data.
			attr :tempfile
			
			# The size of the uploaded data in bytes.
			attr :size
			
			# The submitted content type, if present.
			def content_type
				@headers["content-type"]&.type
			end
		end
		
		# Adapts a chunk-readable protocol body to the IO interface used by the multipart parser.
		class BodyIO
			# Initialize the adapter.
			# @parameter body [Protocol::HTTP::Body::Readable] The chunk-readable request body.
			def initialize(body)
				@body = body
				@buffer = String.new.b
				@closed = false
			end
			
			# Read up to the requested number of bytes without blocking the current fiber.
			# @parameter size [Integer] The maximum number of bytes to read.
			# @parameter output [String | Nil] An optional output buffer.
			# @parameter exception [Boolean] Included for compatibility with IO.
			# @returns [String | Nil] The next bytes, or nil at the end of the body.
			def read_nonblock(size, output = nil, exception: true)
				if @buffer.empty?
					if chunk = @body.read
						@buffer << chunk
					else
						return nil
					end
				end
				
				chunk = @buffer.slice!(0, size)
				
				if output
					output.replace(chunk)
					return output
				else
					return chunk
				end
			end
			
			# Whether the adapter can still be read.
			def readable?
				!@closed
			end
			
			# Whether the adapter has been closed.
			def closed?
				@closed
			end
			
			# Close the adapter and underlying request body.
			def close
				return if @closed
				
				@closed = true
				@body.close
			end
		end
		
		private_constant :BodyIO
		
		# Build a Utopia request from the given protocol request arguments.
		def self.[](*arguments)
			self.new(Protocol::HTTP::Request[*arguments])
		end
		
		# Initialize the request proxy.
		# @parameter delegate [Protocol::HTTP::Request] The underlying protocol request.
		# @parameter request_path [String | Nil] The original path before internal rewrites.
		# @parameter form_data_options [Hash | Nil] Default options for parsing form data.
		def initialize(delegate, request_path: nil, form_data_options: nil)
			@delegate = delegate
			@request_path = request_path
			@form_data_options = form_data_options&.dup&.freeze || {}.freeze
			@session = nil
			@variables = nil
			@locale = nil
			@localization = nil
			@exception = nil
			
			@query_arguments = nil
			@form_data = FORM_DATA_UNDEFINED
			@form_data_effective_options = nil
			@cookies = nil
		end
		
		# The underlying protocol request.
		attr :delegate
		
		# Duplicate the underlying protocol request when duplicating this proxy.
		# @parameter other [Request] The request being copied.
		def initialize_copy(other)
			super
			
			@delegate = other.delegate.dup
			@query_arguments = nil
			@form_data = FORM_DATA_UNDEFINED
			@form_data_effective_options = nil
			@cookies = nil
		end
		
		# Assign the request path including query string.
		def path= value
			if value != @delegate.path
				@request_path ||= self.path_info
			end
			
			@delegate.path = value
			@query_arguments = nil
		end
		
		# Assign the request body and clear any decoded form data.
		# @parameter value [Protocol::HTTP::Body::Readable | Nil] The new request body.
		def body= value
			@delegate.body = value
			@form_data = FORM_DATA_UNDEFINED
			@form_data_effective_options = nil
		end
		
		# Whether the request method is POST.
		def post?
			self.method == "POST"
		end
		
		# The request path without the query string.
		def path_info
			self.path&.split("?", 2)&.first
		end
		
		# Set the request path while preserving the query string.
		def path_info= value
			@request_path ||= self.path_info
			
			if query = self.query
				self.path = "#{value}?#{query}"
			else
				self.path = value
			end
		end
		
		# The original request path, before any internal request rewrites.
		def request_path
			@request_path || self.path_info
		end
		
		# The query string without the leading question mark.
		def query
			path = self.path
			
			if path&.include?("?")
				return path.split("?", 2).last
			end
		end
		
		# Decoded query arguments.
		def query_arguments
			@query_arguments ||= decode_arguments(self.query)
		end
		
		# Decode form data using the request defaults and any endpoint-specific overrides.
		#
		# @parameter options [Hash] Endpoint-specific form-data parsing options.
		# @returns [Hash] The decoded fields and uploads, or an empty hash for an unsupported content type.
		def form_data(**options)
			effective_options = @form_data_options.merge(options)
			
			unless @form_data.equal?(FORM_DATA_UNDEFINED)
				if options.any? and effective_options != @form_data_effective_options
					raise ArgumentError, "Form data has already been decoded with different options!"
				end
				
				return @form_data
			end
			
			form_data = decode_form_data(effective_options)
			@form_data_effective_options = effective_options.freeze
			@form_data = form_data
			
			return form_data
		end
		
		# Decoded request cookies.
		def cookies
			@cookies ||= parse_cookies(self.headers["cookie"])
		end
		
		# The request host with optional port.
		def host
			self.authority || self.headers["host"]
		end
		
		# The request user agent.
		def user_agent
			self.headers["user-agent"]
		end
		
		# The request referrer.
		def referrer
			self.headers["referer"]
		end
		
		# The session associated with this request, if installed.
		attr_accessor :session
		
		# The controller variables associated with this request, if installed.
		attr_accessor :variables
		
		# The locale selected for this request, if any.
		attr_accessor :locale
		
		# The localization middleware associated with this request, if any.
		attr_accessor :localization
		
		# The exception associated with this request, if any.
		attr_accessor :exception
		
		# The remote peer IP address, if available.
		def ip
			self.peer&.ip_address
		end
		
		# The full request URL, if scheme and host are available.
		def url
			if scheme = self.scheme and host = self.host
				"#{scheme}://#{host}#{self.path}"
			else
				self.path
			end
		end
		
		# Build a derived request with updated protocol fields.
		def with(method: self.method, path: self.path, path_info: nil)
			delegate = @delegate.dup
			delegate.method = method
			
			request = self.class.new(delegate, request_path: self.request_path, form_data_options: @form_data_options)
			request.session = @session
			request.variables = @variables
			request.locale = @locale
			request.localization = @localization
			request.exception = @exception
			
			if path_info
				if query = self.query
					request.path = "#{path_info}?#{query}"
				else
					request.path = path_info
				end
			else
				request.path = path
			end
			
			return request
		end
		
		private
		
		# These inherited methods conflict with the protocol request interface, so remove them to allow delegation.
		undef_method :method, :to_s
		
		def method_missing(name, ...)
			if @delegate.respond_to?(name)
				@delegate.public_send(name, ...)
			else
				super
			end
		end
		
		def respond_to_missing?(name, include_private = false)
			@delegate.respond_to?(name) || super(name, include_private)
		end
		
		def decode_arguments(query)
			return {} unless query
			
			parser = Protocol::URL::FormData::Parser.new
			return parser.parse(StringIO.new(query))
		end
		
		def decode_form_data(options)
			value = self.headers["content-type"]
			return {} unless value
			
			content_type = Protocol::Multipart::Header::ContentType.coerce(value)
			
			case content_type.type
			when Protocol::URL::FormData::Parser::CONTENT_TYPE
				return decode_url_encoded_form(options)
			when Protocol::Multipart::FormData::Parser::CONTENT_TYPE
				boundary = content_type["boundary"]
				
				unless boundary
					raise ArgumentError, "Multipart form data is missing a boundary!"
				end
				
				return decode_multipart_form(boundary, **options)
			else
				return {}
			end
		end
		
		def decode_url_encoded_form(options)
			body = self.body
			return {} unless body
			
			parser = Protocol::URL::FormData::Parser.new(**options)
			return parser.parse(body)
		end
		
		def decode_multipart_form(boundary, **options)
			body = self.body
			
			return {} unless body
			
			io = BodyIO.new(body)
			parser = Protocol::Multipart::FormData::Parser.new(**options)
			
			begin
				result = parser.parse(io, boundary:) do |_name, value|
					if value.is_a?(Protocol::Multipart::FormData::Upload)
						create_upload(value)
					else
						value
					end
				end
			ensure
				io.close
			end
			
			return result
		end
		
		def create_upload(upload)
			tempfile = Tempfile.new("utopia-upload", binmode: true)
			
			begin
				upload.each do |chunk|
					tempfile.write(chunk)
				end
				
				tempfile.rewind
				return Upload.new(upload.headers, upload.filename, tempfile, upload.size)
			rescue
				tempfile.close!
				raise
			end
		end
		
		def parse_cookies(cookie_header)
			cookies = {}
			
			return cookies unless cookie_header
			
			if cookie_header.respond_to?(:to_str)
				cookie_header = cookie_header.to_str
			else
				cookie_header = cookie_header.to_s
			end
			
			cookie_header.split(/;\s*/).each do |pair|
				key, value = pair.split("=", 2)
				cookies[key] = value || ""
			end
			
			return cookies
		end
	end
end
