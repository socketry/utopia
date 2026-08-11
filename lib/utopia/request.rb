# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2026, by Samuel Williams.

require "stringio"

require "protocol/http/request"
require "protocol/url"
require "protocol/url/form_data/parser"

require_relative "invalid_path_error"

module Utopia
	# Utopia's application-facing request wrapper.
	#
	# Protocol request methods are delegated to the underlying request; parsing
	# and application conveniences live here rather than on protocol-http itself.
	# External URL paths are normalized once during construction; subsequent
	# request target assignments are trusted internal rewrites.
	class Request
		ASTERISK_PATH = Protocol::URL::Path["*"].freeze
		private_constant :ASTERISK_PATH
		
		# Build a Utopia request from the given protocol request arguments.
		def self.[](*arguments)
			self.new(Protocol::HTTP::Request[*arguments])
		end
		
		# Initialize the request proxy and normalize its external request path.
		# @parameter delegate [Protocol::HTTP::Request] The underlying protocol request.
		def initialize(delegate)
			@delegate = delegate
			@url = nil
			@request_path = nil
			@session = nil
			@variables = nil
			@localization = nil
			@exception = nil
			
			@query_arguments = nil
			@cookies = nil
			
			parse_url!
		end
		
		# The underlying protocol request.
		attr :delegate
		
		# Duplicate the underlying protocol request when duplicating this proxy.
		# @parameter other [Request] The request being copied.
		def initialize_copy(other)
			super
			
			@delegate = other.delegate.dup
			@query_arguments = nil
			@cookies = nil
		end
		
		# Assign the request path including query string.
		def path= value
			@delegate.path = value
			@url = parse_url(value)
			@query_arguments = nil
		end
		
		# Whether the request method is POST.
		def post?
			self.method == "POST"
		end
		
		# The original request path, before any internal request rewrites.
		def request_path
			@request_path || @url&.path
		end
		
		# The query string without the leading question mark.
		def query
			@url&.query
		end
		
		# Decoded query arguments.
		def query_arguments
			@query_arguments ||= decode_arguments(self.query)
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
		
		# The immutable localization preferences associated with this request, if installed.
		attr_accessor :localization
		
		# The exception associated with this request, if any.
		attr_accessor :exception
		
		# The remote peer IP address, if available.
		def ip
			self.peer&.ip_address
		end
		
		# The normalized request URL.
		# @returns [Protocol::URL::Absolute | Protocol::URL::Relative | Nil] The request URL.
		def url
			return unless @url
			return @url if @url.path == ASTERISK_PATH
			
			if scheme = self.scheme and host = self.host
				return Protocol::URL::Absolute.new(scheme, host, @url.path, @url.query).freeze
			end
			
			return @url
		end
		
		# Assign the normalized request URL and update the protocol request target.
		# @parameter url [Protocol::URL::Absolute | Protocol::URL::Relative | String | Nil] The request URL.
		def url=(url)
			url = Protocol::URL[url]
			
			if url&.fragment
				raise ArgumentError, "HTTP request URLs cannot contain a fragment!"
			end
			
			if url.is_a?(Protocol::URL::Absolute)
				@delegate.scheme = url.scheme
				@delegate.authority = url.authority
			end
			
			if url
				self.path = Protocol::URL::Relative.new(url.path, url.query).to_s
			else
				self.path = nil
			end
		end
		
		# Build a derived request with an updated method or URL.
		def with(method: self.method, url: self.url)
			request = self.dup
			request.method = method
			request.url = url
			
			return request
		end
		
		private
		
		# Parse and normalize the untrusted external URL exactly once during construction:
		def parse_url!
			target = @delegate.path
			
			unless target
				return
			end
			
			path, separator, query = target.partition("?")
			path = Protocol::URL::Path[path]
			@request_path = path.freeze
			
			# The asterisk-form is the standard server-wide OPTIONS target:
			if @delegate.method == "OPTIONS" && path == ASTERISK_PATH && separator.empty?
				@url = make_url(path)
				return
			end
			
			if target.include?("#")
				raise InvalidPathError.new(path.encoded, "contains a fragment delimiter")
			end
			
			path = normalize_path(path)
			@url = make_url(path, separator.empty? ? nil : query)
		end
		
		# Parse a trusted internal request target without normalizing its path:
		def parse_url(target)
			return unless target
			
			path, separator, query = target.partition("?")
			return make_url(path, separator.empty? ? nil : query)
		end
		
		# Construct an immutable relative URL for the current request target:
		def make_url(path, query = nil)
			path = Protocol::URL::Path[path].freeze
			query = -query if query
			
			return Protocol::URL::Relative.new(path, query).freeze
		end
		
		# Validate and simplify an untrusted external URL path:
		def normalize_path(path)
			unless path.absolute?
				raise InvalidPathError.new(path.encoded, "expected an absolute path")
			end
			
			begin
				components = path.components
			rescue ArgumentError => error
				raise InvalidPathError.new(path.encoded, error.message)
			end
			
			components.each do |component|
				if component.include?("\\")
					raise InvalidPathError.new(path.encoded, "contains an ambiguous separator")
				end
				
				# Control characters cannot be represented safely in application paths:
				component.b.each_byte do |byte|
					if byte < 32 || byte == 127
						raise InvalidPathError.new(path.encoded, "contains a control character")
					end
				end
			end
			
			return path.simplify.freeze
		end
		
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
