# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2009-2026, by Samuel Williams.

require_relative "client_redirect"

module Utopia
	module Redirection
		# Redirect exact request paths using a lookup table.
		class Rewrite < ClientRedirect
			# Initialize exact-path redirections.
			# @parameter delegate [Protocol::HTTP::Middleware] The downstream middleware.
			# @parameter patterns [Hash(String, String)] The path rewrite patterns.
			# @parameter status [Integer] The redirect response status.
			def initialize(delegate, patterns, status: 301)
				@patterns = patterns
				
				super(delegate, status: status)
			end
			
			# Redirect a path found in the rewrite map.
			# @parameter path [String] The normalized request path.
			# @returns [Protocol::HTTP::Response | Nil] The redirect response when the path is mapped.
			def [](path)
				if location = @patterns[path]
					return redirect(location)
				end
			end
		end
	end
end
