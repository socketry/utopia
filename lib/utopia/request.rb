# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2026, by Samuel Williams.

require "stringio"
require "protocol/http/request"
require "protocol/url"
require "protocol/url/form_data/parser"

require_relative "path"

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
		
		# Initialize the request.
		# @parameter delegate [Protocol::HTTP::Request] The underlying protocol request.
		def initialize(delegate)
			@delegate = delegate
			
			@url = nil
			@session = nil
			@variables = nil
			@localization = nil
			@exception = nil
			
			@query_parameters = nil
			@cookies = nil
		end
		
		# The underlying protocol request.
		attr :delegate
		
		# The session associated with this request, if installed.
		attr_accessor :session
		
		# The controller variables associated with this request, if installed.
		attr_accessor :variables
		
		# The immutable localization preferences associated with this request, if installed.
		attr_accessor :localization
		
		# The exception associated with this request, if any.
		attr_accessor :exception
		
		private def parse_url
			path, query = @delegate.path.split("?", 2)
			
			if scheme = @delegate.scheme and authority = @delegate.authority
				Protocol::URL::Absolute.new(scheme, authority, path, query)
			else
				Protocol::URL::Relative.new(path, query)
			end
		end
		
		# The structured request URL.
		# @returns [Protocol::URL::Absolute | Protocol::URL::Relative | Nil] The request URL.
		def url
			@url ||= self.parse_url.normalize!
		end
		
		# @returns [Utopia::Path] The path components.
		def path
			Path.new(self.url.path.components(Protocol::URL::Encoding::System))
		end
		
		# Assign the decoded application path while preserving the current query string.
		# @parameter value [Utopia::Path | Protocol::URL::Path | String] The path.
		def path= value
			if value.is_a?(Protocol::URL::Path)
				self.url.path = value
			else
				self.url.path = Path[value].to_url_path
			end
		end
		
		# Whether the request method is QUERY.
		# @returns [Boolean] Whether the request method is QUERY.
		def query?
			@delegate.method == "QUERY"
		end
		
		# Whether the request method is POST.
		def post?
			@delegate.method == "POST"
		end
		
		# The normalized original request path, before any internal request rewrites.
		# @returns [Utopia::Path] The decoded application path.
		def request_path
			path = @delegate.path.split("?", 2).first
			path = Protocol::URL::Path[path].normalize.simplify
			
			return Path.new(path.components(Protocol::URL::Encoding::System))
		end
		
		QUERY_PARSER = Protocol::URL::FormData::Parser.new
		
		private def parse_query_parameters(query)
			if query
				return QUERY_PARSER.parse(StringIO.new(query))
			else
				Hash.new
			end
		end
		
		# Decoded query arguments.
		def query_parameters
			@query_parameters ||= parse_query_parameters(self.url.query)
		end
		
		private def parse_cookies(cookie_header)
			cookies = {}
			
			return cookies unless cookie_header
			
			cookie_header = cookie_header.to_s
			
			cookie_header.split(/;\s*/).each do |pair|
				key, value = pair.split("=", 2)
				cookies[key] = value || ""
			end
			
			return cookies
		end
		
		# Decoded request cookies.
		def cookies
			@cookies ||= parse_cookies(self.headers["cookie"])
		end
		
		# The request user agent.
		def user_agent
			@delegate.headers["user-agent"]
		end
		
		# The request referrer.
		def referrer
			@delegate.headers["referer"]
		end
		
		# The remote peer IP address, if available.
		def ip
			@delegate.peer&.ip_address
		end
		
		# Assign the structured request URL.
		# @parameter url [Protocol::URL::Absolute | Protocol::URL::Relative | String | Nil] The request URL.
		def url= url
			@url = Protocol::URL[url]
			@query_parameters = nil
		end
		
		# Build a derived request with updated protocol fields.
		def with(method: nil, path: self.path)
			delegate = @delegate
			
			if method
				delegate = @delegate.dup
				delegate.method = method
			end
			
			request = self.class.new(delegate)
			request.session = @session
			request.variables = @variables
			request.localization = @localization
			request.exception = @exception
			request.path = path
			
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
	end
end
