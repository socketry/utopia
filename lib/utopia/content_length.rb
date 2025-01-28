# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2016-2025, by Samuel Williams.

require_relative "middleware"

module Utopia
	# A faster implementation of Rack::ContentLength which doesn't rewrite body, but does expect it to either be an Array or an object that responds to #bytesize.
	class ContentLength
		def initialize(app)
			@app = app
		end
		
		def content_length_of(body)
			if body.respond_to?(:map)
				return body.map(&:bytesize).reduce(0, :+)
			end
		end
		
		def call(env)
			response = @app.call(env)
			
			unless response[2]&.empty? or response[1].include?(Rack::CONTENT_LENGTH)
				if content_length = self.content_length_of(response[2])
					response[1][Rack::CONTENT_LENGTH] = content_length
				end
			end
			
			return response
		end
	end
end
