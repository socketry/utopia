# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2026, by Samuel Williams.

require_relative "client_redirect"

module Utopia
	module Redirection
		# Redirect urls that end with a `/`, e.g. directories.
		class DirectoryIndex < ClientRedirect
			# Initialize directory-index redirection.
			# @parameter app [Interface(:call)] The downstream application.
			# @parameter index [Integer] The index.
			def initialize(app, index: "index")
				@index = index
				
				super(app)
			end
			
			# Freeze this object and its internal state.
			# @returns [self] This object.
			def freeze
				return self if frozen?
				
				@index.freeze
				
				return super
			end
			
			# Redirect a directory path to its index path.
			# @parameter path [String] The normalized request path.
			# @returns [Protocol::HTTP::Response | Nil] The redirect response when the path ends with `/`.
			def [] path
				if path.end_with?("/")
					return redirect(path + @index)
				end
			end
		end
	end
end
