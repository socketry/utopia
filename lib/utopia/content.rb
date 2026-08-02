# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2009-2025, by Samuel Williams.

require_relative "content/middleware"

module Utopia
	# Builds middleware for serving filesystem-backed dynamic content.
	module Content
		# Construct content middleware.
		# @returns [Content::Middleware] The content middleware.
		def self.new(...)
			Middleware.new(...)
		end
	end
end
