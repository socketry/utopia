# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2026, by Samuel Williams.

require "cgi"
require "uri"

require "protocol/http/request"

require_relative "session"

module Utopia
	# Utopia's application-facing request wrapper.
	#
	# The underlying protocol request is available via {#http}; parsing and
	# application conveniences live here rather than on protocol-http itself.
	class Request
		CURRENT_KEY = :utopia_request
		
		# The current Utopia request wrapper.
		def self.current
			Fiber[CURRENT_KEY]
		end
		
		# Assign the current Utopia request wrapper.
		def self.current= request
			Fiber[CURRENT_KEY] = request
		end
		
		# The current Utopia request wrapper, or raise if none is installed.
		def self.current!
			self.current or raise RuntimeError, "No current Utopia request!"
		end
		
		# Build a Utopia request from the given protocol request arguments.
		def self.[](*arguments)
			self.new(Protocol::HTTP::Request[*arguments])
		end
		
		# Initialize the request wrapper.
		# @parameter http [Protocol::HTTP::Request] The underlying protocol request.
		# @parameter request_path [String | Nil] The original path before internal rewrites.
		def initialize(http, request_path: nil)
			@http = http
			@request_path = request_path
			
			@arguments = nil
			@cookies = nil
		end
		
		# The underlying protocol request.
		attr :http
		
		# The HTTP request method.
		def method
			@http.method
		end
		
		# Assign the HTTP request method.
		def method= value
			@http.method = value
		end
		
		alias request_method method
		
		# The request path including query string.
		def path
			@http.path
		end
		
		# Assign the request path including query string.
		def path= value
			@request_path ||= self.path_info if value != @http.path
			@http.path = value
			@arguments = nil
		end
		
		# The protocol request headers.
		def headers
			@http.headers
		end
		
		# The protocol request body.
		def body
			@http.body
		end
		
		# Assign the protocol request body.
		def body= value
			@http.body = value
		end
		
		# The request scheme.
		def scheme
			@http.scheme
		end
		
		# Assign the request scheme.
		def scheme= value
			@http.scheme = value
		end
		
		# The request authority.
		def authority
			@http.authority
		end
		
		# Assign the request authority.
		def authority= value
			@http.authority = value
		end
		
		# The remote peer, if available.
		def peer
			@http.peer
		end
		
		# Whether the request method is GET.
		def get?
			self.method == "GET"
		end
		
		# Whether the request method is HEAD.
		def head?
			self.method == "HEAD"
		end
		
		# Whether the request method is POST.
		def post?
			self.method == "POST"
		end
		
		# Whether the request method is PUT.
		def put?
			self.method == "PUT"
		end
		
		# Whether the request method is PATCH.
		def patch?
			self.method == "PATCH"
		end
		
		# Whether the request method is DELETE.
		def delete?
			self.method == "DELETE"
		end
		
		# Whether the request method is OPTIONS.
		def options?
			self.method == "OPTIONS"
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
			self.path&.split("?", 2)&.last if self.path&.include?("?")
		end
		
		# Decoded query arguments.
		def arguments
			@arguments ||= decode_arguments(self.query)
		end
		
		alias params arguments
		
		# Decoded request cookies.
		def cookies
			@cookies ||= parse_cookies(self.headers["cookie"])
		end
		
		# The request host with optional port.
		def host
			self.authority || self.headers["host"]
		end
		
		alias host_with_port host
		
		# Whether the request uses HTTPS.
		def ssl?
			self.scheme == "https"
		end
		
		# The base URL for the request.
		def base_url
			if self.scheme && self.host
				"#{self.scheme}://#{self.host}"
			else
				""
			end
		end
		
		# The request user agent.
		def user_agent
			self.headers["user-agent"]
		end
		
		# The request referrer.
		def referrer
			self.headers["referer"]
		end
		
		alias referer referrer
		
		# The current Utopia session, if installed.
		def session
			Utopia::Session.current
		end
		
		# The remote peer IP address, if available.
		def ip
			self.peer&.ip_address
		end
		
		# The full request URL, if scheme and host are available.
		def url
			base_url = self.base_url
			
			if !base_url.empty?
				"#{base_url}#{self.path}"
			else
				self.path
			end
		end
		
		# Build a derived request with updated protocol fields.
		def with(method: self.method, path: self.path, path_info: nil)
			http = @http.dup
			http.method = method
			
			request = self.class.new(http, request_path: self.request_path)
			
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
		
		# Fetch a Rack-style compatibility value or query argument.
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
				else
					self.arguments[key.to_s]
				end
			end
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
