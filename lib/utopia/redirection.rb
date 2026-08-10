# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2009-2026, by Samuel Williams.

module Utopia
	# Redirect requests and replace unhandled error responses with error documents.
	module Redirection
		# We cache redirects for 24 hours by default.
		DEFAULT_MAX_AGE = 3600*24
	end
end

require_relative "redirection/request_failure"
require_relative "redirection/rule"
require_relative "redirection/builder"
require_relative "redirection/middleware"

module Utopia
	module Redirection
		# Construct unified redirection middleware.
		# @parameter delegate [Protocol::HTTP::Middleware] The downstream middleware.
		# @yields {|builder| ...} The redirection configuration.
		# @returns [Middleware] The configured middleware.
		def self.new(delegate, &block)
			builder = Builder.new.build(&block)
			return Middleware.new(delegate, builder)
		end
	end
end
