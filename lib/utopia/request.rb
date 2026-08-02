# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2026, by Samuel Williams.

require "uri"

require "protocol/http/request"

module Utopia
	# Utopia's application-facing request wrapper.
	#
	# Protocol request methods are delegated to the underlying request; parsing
	# and application conveniences live here rather than on protocol-http itself.
	class Request
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
			@session = nil
			@variables = nil
			@locale = nil
			@localization = nil
			@exception = nil
			
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
		
		# Assign the request path including query string.
		def path= value
			if value != @delegate.path
				@request_path ||= self.path_info
			end
			
			@delegate.path = value
			@arguments = nil
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
			
			request = self.class.new(delegate, request_path: self.request_path)
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
				cookies[key] = value || ""
			end
			
			return cookies
		end
	end
end
