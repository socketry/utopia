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
	# Protocol request methods are delegated to the underlying request; parsing
	# and application conveniences live here rather than on protocol-http itself.
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
		
		# Initialize the request proxy.
		# @parameter delegate [Protocol::HTTP::Request] The underlying protocol request.
		# @parameter request_path [String | Nil] The original path before internal rewrites.
		def initialize(delegate, request_path: nil)
			@delegate = delegate
			@request_path = request_path
			
			@arguments = nil
			@cookies = nil
		end
		
		# The underlying protocol request.
		attr :delegate
		
		# Duplicate the underlying protocol request when duplicating this proxy.
		# @parameter other [Request] The request being copied.
		def initialize_copy(other)
			super
			
			@delegate = other.delegate.dup
			@arguments = nil
			@cookies = nil
		end
		
		# The HTTP request method.
		def request_method
			self.method
		end
		
		# Assign the request path including query string.
		def path= value
			@request_path ||= self.path_info if value != @delegate.path
			@delegate.path = value
			@arguments = nil
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
			delegate = @delegate.dup
			delegate.method = method
			
			request = self.class.new(delegate, request_path: self.request_path)
			
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
