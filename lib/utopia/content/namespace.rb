# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2017-2026, by Samuel Williams.

module Utopia
	module Content
		# A namespace which contains tags which can be rendered within a {Document}.
		module Namespace
			# Initialize tag mappings on an extended namespace.
			# @parameter other [Module] The namespace being extended.
			# @returns [Hash] The initialized tag mappings.
			def self.extended(other)
				other.class_exec do
					@named = {}
				end
			end
			
			attr :named
			
			# Freeze this object and its internal state.
			# @returns [self] This object.
			def freeze
				return self if frozen?
				
				@named.freeze
				@named.values.each(&:freeze)
				
				super
			end
			
			# Tag.
			# @parameter name [String] The name.
			# @parameter klass [Class] The class to configure.
			# @returns [Class | Proc] The registered tag implementation.
			def tag(name, klass = nil, &block)
				@named[name] = klass || block
			end
			
			# @return [Node] The node which should be used to render the named tag.
			def call(name, node)
				@named[name]
			end
		end
	end
end
