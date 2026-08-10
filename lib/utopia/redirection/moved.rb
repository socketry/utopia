# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2009-2026, by Samuel Williams.

require_relative "client_redirect"

module Utopia
	module Redirection
		# Redirect request paths from one prefix to another.
		class Moved < ClientRedirect
			# Initialize prefix redirection behavior.
			# @parameter delegate [Protocol::HTTP::Middleware] The downstream middleware.
			# @parameter pattern [String] The path prefix to replace.
			# @parameter prefix [String] The replacement prefix.
			# @parameter status [Integer] The redirect response status.
			# @parameter flatten [Boolean] Whether to discard the matched path suffix.
			def initialize(delegate, pattern, prefix, status: 301, flatten: false)
				@pattern = pattern
				@prefix = prefix
				@flatten = flatten
				
				super(delegate, status: status)
			end
			
			# Redirect a matching path to the configured prefix.
			# @parameter path [String] The normalized request path.
			# @returns [Protocol::HTTP::Response | Nil] The redirect response when the pattern matches.
			def [](path)
				if path.start_with?(@pattern)
					if @flatten
						return redirect(@prefix)
					else
						return redirect(path.sub(@pattern, @prefix))
					end
				end
			end
		end
	end
end
