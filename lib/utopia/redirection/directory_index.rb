# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2009-2026, by Samuel Williams.

require_relative "client_redirect"

module Utopia
	module Redirection
		# Redirect directory paths to an index path.
		class DirectoryIndex < ClientRedirect
			# Initialize directory-index redirection.
			# @parameter delegate [Protocol::HTTP::Middleware] The downstream middleware.
			# @parameter index [String] The index path component.
			def initialize(delegate, index: "index")
				@index = index
				
				super(delegate)
			end
			
			# Redirect a directory path to its index path.
			# @parameter path [String] The normalized request path.
			# @returns [Protocol::HTTP::Response | Nil] The redirect response when the path ends with `/`.
			def [](path)
				if path.end_with?("/")
					return redirect(path + @index)
				end
			end
		end
	end
end
