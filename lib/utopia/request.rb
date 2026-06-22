# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2026, by Samuel Williams.

require "cgi"
require "uri"

require "protocol/http/headers"
require "protocol/http/request"

module Utopia
	# The application-facing request wrapper.
	#
	# This class intentionally keeps a small surface area. Framework features such
	# as arguments, sessions, localization and controller variables should be added
	# as explicit Utopia concepts rather than relying on transport-specific state.
	class Request
		# Wrap either a {Protocol::HTTP::Request} or an existing Utopia request.
		def self.wrap(request)
			case request
			when self
				request
			when Protocol::HTTP::Request
				self.new(request)
			else
				raise ArgumentError, "Unable to wrap request: #{request.inspect}!"
			end
		end
		
		# Initialize a request wrapper.
		# @parameter http [Protocol::HTTP::Request] The underlying protocol request.
		# @parameter attributes [Hash | Nil] Request-local application state.
		def initialize(http, attributes: nil)
			@http = http
			@attributes = attributes || {}
			
			@attributes["REQUEST_PATH"] ||= self.path_info
		end
		
		# The underlying {Protocol::HTTP::Request}.
		attr :http
		
		# Request-local application state.
		attr :attributes
		
		# Fetch request-local application state.
		def [] key
			case key
			when "REQUEST_METHOD"
				self.method
			when "PATH_INFO", "REQUEST_PATH"
				self.path_info
			when "QUERY_STRING"
				self.query.to_s
			when "HTTP_HOST"
				self.host
			when "HTTP_USER_AGENT"
				self.user_agent
			when "HTTP_ACCEPT_LANGUAGE"
				self.headers["accept-language"]
			when "HTTP_IF_MODIFIED_SINCE"
				self.headers["if-modified-since"]
			when "HTTP_IF_NONE_MATCH"
				self.headers["if-none-match"]
			when "HTTP_RANGE"
				self.headers["range"]
			else
				if key.is_a?(String) && key.start_with?("HTTP_")
					self.headers[key[5..].downcase.tr("_", "-")]
				elsif @attributes.key?(key)
					@attributes[key]
				elsif key.is_a?(Symbol) && @attributes.key?(key.to_s)
					@attributes[key.to_s]
				else
					self.arguments[key.to_s]
				end
			end
		end
		
		# Assign request-local application state.
		def []= key, value
			case key
			when "REQUEST_METHOD"
				@http.method = value
			when "PATH_INFO"
				self.path_info = value
			else
				@attributes[key] = value
			end
		end
		
		# Fetch request-local application state.
		def fetch(...)
			@attributes.fetch(...)
		end
		
		# Select request-local application state.
		def select(&block)
			@attributes.select(&block)
		end
		
		# Build a derived request with the specified attributes merged in.
		def merge(attributes)
			return self.with(attributes: attributes)
		end
		
		# Build a derived request with updated protocol fields and request-local state.
		def with(method: self.method, path: self.path, path_info: nil, attributes: {})
			http = @http.dup
			http.method = method
			
			if path_info
				if query = self.query
					http.path = "#{path_info}?#{query}"
				else
					http.path = path_info
				end
			else
				http.path = path
			end
			
			return self.class.new(http, attributes: @attributes.merge(attributes))
		end
		
		# @returns [String] The HTTP request method.
		def method
			@http.method
		end
		alias request_method method
		
		# @returns [Boolean] Whether the HTTP request method is GET.
		def get?
			@http.method == "GET"
		end
		
		# @returns [Boolean] Whether the HTTP request method is HEAD.
		def head?
			@http.method == "HEAD"
		end
		
		# @returns [Boolean] Whether the HTTP request method is POST.
		def post?
			@http.method == "POST"
		end
		
		# @returns [Boolean] Whether the HTTP request method is PUT.
		def put?
			@http.method == "PUT"
		end
		
		# @returns [Boolean] Whether the HTTP request method is PATCH.
		def patch?
			@http.method == "PATCH"
		end
		
		# @returns [Boolean] Whether the HTTP request method is DELETE.
		def delete?
			@http.method == "DELETE"
		end
		
		# @returns [Boolean] Whether the HTTP request method is OPTIONS.
		def options?
			@http.method == "OPTIONS"
		end
		
		# @returns [String] The full request path, including query string.
		def path
			@http.path
		end
		
		# Set the full request path.
		# @parameter value [String] The full request path, including optional query string.
		def path=(value)
			@http.path = value
		end
		
		# @returns [String | Nil] The request path without query string.
		def path_info
			@http.path&.split("?", 2)&.first
		end
		
		# Set the request path while preserving the current query string.
		# @parameter value [String] The request path without query string.
		def path_info=(value)
			if query = self.query
				@http.path = "#{value}?#{query}"
			else
				@http.path = value
			end
		end
		
		# @returns [String | Nil] The query string without the leading `?`.
		def query
			@http.path&.split("?", 2)&.last if @http.path&.include?("?")
		end
		
		# @returns [Hash] The decoded query arguments.
		def arguments
			@arguments ||= decode_arguments(self.query)
		end
		alias params arguments
		
		# @returns [Hash] The decoded request cookies.
		def cookies
			@cookies ||= parse_cookies(@http.headers["cookie"])
		end
		
		# @returns [String | Nil] The request host.
		def host
			@http.authority || @http.headers["host"]
		end
		alias host_with_port host
		
		# @returns [String | Nil] The request URL scheme.
		def scheme
			@http.scheme
		end
		
		# @returns [Boolean] Whether the request URL scheme is HTTPS.
		def ssl?
			self.scheme == "https"
		end
		
		# @returns [String] The request base URL if scheme and host are available.
		def base_url
			scheme = self.scheme
			host = self.host
			
			if scheme && host
				"#{scheme}://#{host}"
			else
				""
			end
		end
		
		# @returns [String | Nil] The request user agent.
		def user_agent
			@http.headers["user-agent"]
		end
		
		# @returns [String | Nil] The request referrer.
		def referrer
			@http.headers["referer"]
		end
		alias referer referrer
		
		# @returns [Hash | Nil] The request session, if installed by Utopia::Session.
		def session
			@attributes["utopia.session"]
		end
		
		# @returns [String | Nil] The remote peer address, if available.
		def ip
			@http.peer&.ip_address
		end
		
		# @returns [String] The full request URL if scheme and host are available.
		def url
			base_url = self.base_url
			
			if !base_url.empty?
				"#{base_url}#{self.path}"
			else
				self.path
			end
		end
		
		# @returns [Protocol::HTTP::Headers] The request headers.
		def headers
			@http.headers
		end
		
		# @returns [Protocol::HTTP::Body::Readable | Nil] The request body.
		def body
			@http.body
		end
		
		private
		
		def decode_arguments(query)
			arguments = {}
			
			return arguments unless query
			
			URI.decode_www_form(query).each do |key, value|
				values = arguments.fetch(key){arguments[key] = []}
				values << value
			end
			
			arguments.transform_values! do |values|
				if values.size == 1
					values.first
				else
					values
				end
			end
			
			return arguments
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
				cookies[CGI.unescape(key)] = CGI.unescape(value || "")
			end
			
			return cookies
		end
	end
end
