# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2026, by Samuel Williams.

module Utopia
	module Redirection
		# Builds immutable redirection rules for {Middleware}.
		class Builder
			# The default redirect cache lifetime is 24 hours.
			MAX_AGE = 3600*24
			
			def initialize
				@rules = []
				@errors = {}
			end
			
			# The configured request redirection rules.
			# @returns [Array] The rules in declaration order.
			attr :rules
			
			# The configured error document paths indexed by response status.
			# @returns [Hash(Integer, String)] The configured error documents.
			attr :errors
			
			# Configure and freeze this builder.
			# @yields {|builder| ...} The redirection configuration.
			# @returns [self] This builder.
			def build(&block)
				if block
					if block.arity.zero?
						instance_exec(&block)
					else
						block.call(self)
					end
				end
				
				freeze
				
				return self
			end
			
			# Freeze this builder and its configured rules.
			# @returns [self] This builder.
			def freeze
				return self if frozen?
				
				@rules.freeze
				@errors.freeze
				
				return super
			end
			
			# Add an exact-path rewrite map.
			# @parameter patterns [Hash(String, String)] Exact paths and their destinations.
			# @parameter status [Integer] The redirect response status.
			# @parameter max_age [Integer] The redirect cache lifetime in seconds.
			# @returns [self] This builder.
			def rewrite(patterns = nil, status: 301, max_age: MAX_AGE, **keyword_patterns)
				# Ruby interprets an unbraced path map as keyword arguments:
				if patterns.nil?
					patterns = keyword_patterns
				end
				
				patterns = patterns.dup.freeze
				
				add(status, max_age) do |path|
					patterns[path]
				end
				
				return self
			end
			
			# Redirect paths ending in a slash to an index path.
			# @parameter index [String] The index path component.
			# @parameter status [Integer] The redirect response status.
			# @parameter max_age [Integer] The redirect cache lifetime in seconds.
			# @returns [self] This builder.
			def directory_index(index = "index", status: 307, max_age: MAX_AGE)
				add(status, max_age) do |path|
					if path.end_with?("/")
						path + index
					end
				end
				
				return self
			end
			
			# Redirect paths beginning with one prefix to another prefix.
			# @parameter pattern [String] The source path prefix.
			# @parameter prefix [String] The destination path prefix.
			# @parameter status [Integer] The redirect response status.
			# @parameter flatten [Boolean] Whether to discard the matched path suffix.
			# @parameter max_age [Integer] The redirect cache lifetime in seconds.
			# @returns [self] This builder.
			def moved(pattern, prefix, status: 301, flatten: false, max_age: MAX_AGE)
				add(status, max_age) do |path|
					if path.start_with?(pattern)
						if flatten
							prefix
						else
							path.sub(pattern, prefix)
						end
					end
				end
				
				return self
			end
			
			# Replace an unhandled response status with an internal error document.
			# @parameter status [Integer] The response status to handle.
			# @parameter path [String] The internal error document path.
			# @returns [self] This builder.
			def error(status, path)
				@errors[status] = path
				return self
			end
			
			private
			
			def add(status, max_age, &resolver)
				@rules << Rule.new(status, max_age, resolver)
			end
		end
	end
end
