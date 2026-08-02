# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2025, by Samuel Williams.

require "xrb/builder"

module Utopia
	module Content
		DEFERRED_TAG_NAME = "utopia:deferred".freeze
		
		# A builder for rendering Utopia content that extends XRB::Builder with Utopia-specific functionality.
		class Builder < XRB::Builder
			# Initialize rendering state for a content node.
			# @parameter parent [Builder | nil] The enclosing builder state.
			# @parameter tag [XRB::Tag | nil] The tag that opened this state.
			# @parameter node [Utopia::Content::Node] The content node.
			# @parameter attributes [Hash] The attributes.
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
			
			# Insert a deferred-content marker and retain its rendering block.
			# @parameter value [Object | nil] An unused compatibility argument.
			# @yields {|document| ...} The deferred rendering operation.
			# @returns [String] The closed deferred-content tag.
			def defer(value = nil, &block)
				@deferred << block
				
				XRB::Tag.closed(DEFERRED_TAG_NAME, :id => @deferred.size - 1)
			end
			
			# Fetch an attribute for the current content node.
			# @parameter key [String | Symbol] The lookup key.
			# @returns [Object | nil] The attribute value.
			def [](key)
				@attributes[key]
			end
			
			# Render this node's captured content into a document.
			# @parameter document [Utopia::Content::Document] The content document.
			# @returns [String] The rendered output buffer.
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
			
			# Write a complete tag to the output.
			# @parameter tag [XRB::Tag] The tag.
			# @returns [String] The output buffer.
			def tag_complete(tag)
				tag.write(@output)
			end
			
			# Whether this state has any nested tags.
			def empty?
				@tags.empty?
			end
			
			# Tag begin.
			# @parameter tag [XRB::Tag] The opening tag.
			# @returns [String] The output buffer.
			def tag_begin(tag)
				@tags << tag
				tag.write_opening_tag(@output)
			end
			
			# Tag end.
			# @parameter tag [XRB::Tag] The closing tag.
			# @returns [String] The output buffer.
			# @raises [UnbalancedTagError] If the closing tag does not match the most recent opening tag.
			def tag_end(tag)
				raise UnbalancedTagError.new(tag) unless @tags.pop.name == tag.name
				tag.write_closing_tag(@output)
			end
		end
	end
end
