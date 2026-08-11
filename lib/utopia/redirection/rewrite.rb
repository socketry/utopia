# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2009-2026, by Samuel Williams.

require_relative "client_redirect"

module Utopia
	module Redirection
		# Rewrite requests that match the given pattern to a single destination.
		class Rewrite < ClientRedirect
			# Initialize exact-path redirections.
			# @parameter app [Interface(:call)] The downstream application.
			# @parameter patterns [Hash] The path rewrite patterns.
			# @parameter status [Integer] The status.
			def initialize(app, patterns, status: 301)
				@patterns = patterns
				
				super(app, status: status)
			end
			
			# Redirect a path found in the rewrite map.
			# @parameter path [String] The normalized request path.
			# @returns [Protocol::HTTP::Response | Nil] The redirect response when the path is mapped.
			def [] path
				if location = @patterns[path]
					return redirect(location)
				end
			end
		end
	end
end
