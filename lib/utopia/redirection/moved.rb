# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2026, by Samuel Williams.

require_relative "client_redirect"

module Utopia
	module Redirection
		# Rewrite requests that match the given pattern to a new prefix.
		class Moved < ClientRedirect
			# Initialize prefix redirection behavior.
			# @parameter app [Interface(:call)] The downstream application.
			# @parameter pattern [Regexp] The path pattern.
			# @parameter prefix [String] The prefix.
			# @parameter status [Integer] The status.
			# @parameter flatten [bool] Whether to flatten the rewritten path.
			def initialize(app, pattern, prefix, status: 301, flatten: false)
				@pattern = pattern
				@prefix = prefix
				@flatten = flatten
				
				super(app, status: status)
			end
			
			# Redirect a matching path to the configured prefix.
			# @parameter path [String] The normalized request path.
			# @returns [Protocol::HTTP::Response | Nil] The redirect response when the pattern matches.
			def [] path
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
