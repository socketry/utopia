# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2017-2022, by Samuel Williams.

module Utopia
	class Content
		# A namespace which contains tags which can be rendered within a {Document}.
		module Namespace
			def self.extended(other)
				other.class_exec do
					@named = {}
				end
			end
			
			attr :named
			
			def freeze
				return self if frozen?
				
				@named.freeze
				@named.values.each(&:freeze)
				
				super
			end
			
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
