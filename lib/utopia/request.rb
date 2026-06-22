# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2026, by Samuel Williams.

module Utopia
	# The application-facing request wrapper.
	#
	# This class intentionally keeps a small surface area. Framework features such
	# as arguments, sessions, localization and controller variables should be added
	# as explicit Utopia concepts rather than relying on a Rack-style env hash.
	class Request
		def initialize(http, attributes: nil)
			@http = http
			@attributes = attributes || {}
		end
		
		# The underlying {Protocol::HTTP::Request}.
		attr :http
		
		# Request-local application state.
		attr :attributes
		
		def method
			@http.method
		end
		
		def path
			@http.path
		end
		
		def path=(value)
			@http.path = value
		end
		
		def path_info
			@http.path&.split("?", 2)&.first
		end
		
		def path_info=(value)
			if query = self.query
				@http.path = "#{value}?#{query}"
			else
				@http.path = value
			end
		end
		
		def query
			@http.path&.split("?", 2)&.last if @http.path&.include?("?")
		end
		
		def headers
			@http.headers
		end
		
		def body
			@http.body
		end
	end
end
