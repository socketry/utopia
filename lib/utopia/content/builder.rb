# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2025, by Samuel Williams.

require "xrb/builder"

module Utopia
	module Content
		DEFERRED_TAG_NAME = "utopia:deferred".freeze
		
		# A builder for rendering Utopia content that extends XRB::Builder with Utopia-specific functionality.
		class Builder < XRB::Builder
			def initialize(parent, tag, node, attributes = tag.to_hash, **options)
				super(**options)
				
				@parent = parent
				@tag = tag
				@node = node
				@attributes = attributes
				
				@content = nil
				@deferred = []
				@tags = []
			end
			
			attr :parent
			attr :tag
			attr :attributes
			attr :content
			attr :node
			
			# A list of all tags in order of rendering them, which have not been finished yet.
			attr :tags
			
			attr :deferred
			
			def defer(value = nil, &block)
				@deferred << block
				
				XRB::Tag.closed(DEFERRED_TAG_NAME, :id => @deferred.size - 1)
			end
			
			def [](key)
				@attributes[key]
			end
			
			def call(document)
				@content = @output.dup
				@output.clear
				
				if node.respond_to? :call
					node.call(document, self)
				else
					document.parse_markup(@content)
				end
				
				return @output
			end
			
			# Override write to directly append to output
			def write(string)
				@output << string
			end
			
			# Override text to handle build_markup protocol
			def text(content)
				return unless content
				
				if content.respond_to?(:build_markup)
					content.build_markup(self)
				else
					XRB::Markup.append(@output, content)
				end
			end
			
			def tag_complete(tag)
				tag.write(@output)
			end
			
			# Whether this state has any nested tags.
			def empty?
				@tags.empty?
			end
			
			def tag_begin(tag)
				@tags << tag
				tag.write_opening_tag(@output)
			end
			
			def tag_end(tag)
				raise UnbalancedTagError.new(tag) unless @tags.pop.name == tag.name
				tag.write_closing_tag(@output)
			end
		end
	end
end
