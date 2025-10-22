# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2010-2025, by Samuel Williams.

module Utopia
	module Content
		# Compatibility with older versions of rack:
		EXPIRES = "expires".freeze
		CACHE_CONTROL = "cache-control".freeze
		CONTENT_TYPE = "content-type".freeze
		NO_CACHE = "no-cache".freeze
		
		# A basic content response, including useful defaults for typical HTML5 content.
		class Response
			def initialize
				@status = 200
				@headers = {}
				@body = []
				
				# The default content type:
				self.content_type = "text/html; charset=utf-8"
			end
			
			attr_accessor :status
			attr :headers
			attr :body
			
			def content
				@body.join
			end
			
			def lookup(tag)
				return nil
			end
			
			def to_a
				[@status, @headers, @body]
			end
			
			# Specifies that the content shouldn't be cached. Overrides `cache!` if already called.
			def do_not_cache!
				@headers[CACHE_CONTROL] = "no-cache, must-revalidate"
				@headers[EXPIRES] = Time.now.httpdate
			end
			
			# Specify that the content could be cached.
			def cache!(duration = 3600, access: "public")
				unless cache_control = @headers[CACHE_CONTROL] and cache_control.include?(NO_CACHE)
					@headers[CACHE_CONTROL] = "#{access}, max-age=#{duration}"
					@headers[EXPIRES] = (Time.now + duration).httpdate
				end
			end
			
			# Specify the content type of the response data.
			def content_type= value
				@headers[CONTENT_TYPE] = value
			end
			
			alias content_type! content_type=
		end
	end
end
