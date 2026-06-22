# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2026, by Samuel Williams.

require "protocol/http/response"
require "protocol/http/middleware"

module Utopia
	# Response helpers for Utopia applications.
	#
	# The canonical transport response remains {Protocol::HTTP::Response}. This
	# module provides convenience constructors and normalization at the application
	# boundary.
	module Response
		CONTENT_TYPE = "content-type".freeze
		LOCATION = "location".freeze
		
		NotFound = Protocol::HTTP::Middleware::NotFound
		
		def self.[](status, headers = nil, body = nil, **options)
			Protocol::HTTP::Response[status, headers, body, **options]
		end
		
		def self.wrap(response)
			case response
			when Protocol::HTTP::Response
				response
			when Array
				Protocol::HTTP::Response[*response]
			else
				if response.respond_to?(:to_protocol_response)
					response.to_protocol_response
				elsif response.respond_to?(:to_ary)
					Protocol::HTTP::Response[*response.to_ary]
				else
					response
				end
			end
		end
		
		def self.redirect(location, status = 302, headers = {})
			self[status, headers.merge(LOCATION => location), []]
		end
		
		def self.text(content, status = 200, headers = {})
			self[status, {CONTENT_TYPE => "text/plain; charset=utf-8"}.merge(headers), [content]]
		end
		
		def self.html(content, status = 200, headers = {})
			self[status, {CONTENT_TYPE => "text/html; charset=utf-8"}.merge(headers), [content]]
		end
	end
end
