# Copyright, 2012, by Samuel G. D. Williams. <http://www.codeotaku.com>
# 
# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:
# 
# The above copyright notice and this permission notice shall be included in
# all copies or substantial portions of the Software.
# 
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
# THE SOFTWARE.

require_relative 'links'
require_relative 'response'
require_relative 'markup'

module Utopia
	class Content
		# This error is thrown if a tag doesn't match up when parsing the 
		class UnbalancedTagError < StandardError
			def initialize(tag)
				@tag = tag
				
				super "Unbalanced tag #{tag.name}"
			end
			
			attr :tag
		end
		
		# A single request through content middleware. We use a struct to hide instance varibles since we instance_exec within this context.
		class Document < Response
			def self.render(node, request, attributes)
				document = self.new(request, attributes)
				
				document.body << document.render_node(node, attributes)
				
				return document
			end
			
			def initialize(request, attributes = {})
				@request = request
				
				@attributes = attributes
				
				@begin_tags = []
				@end_tags = []
				
				super()
			end
			
			# A helper method for accessing controller variables from view:
			def controller
				@controller ||= Utopia::Controller[request]
			end
			
			def localization
				@localization ||= Utopia::Localization[request]
			end

			def parse_markup(markup)
				MarkupParser.parse(markup, self)
			end

			# The Rack::Request for this document.
			attr :request

			# Per-document global attributes.
			attr :attributes

			# Begin tags represents a list from outer to inner most tag.
			# At any point in parsing markup, begin_tags is a list of the inner most tag,
			# then the next outer tag, etc. This list is used for doing dependent lookups.
			attr :begin_tags

			# End tags represents a list of execution order. This is the order that end tags
			# have appeared when evaluating nodes.
			attr :end_tags

			def tag(name, attributes = {}, &block)
				# If we provide a block which can give inner data, we are not self-closing.
				tag = Tag.new(name, !block_given?, attributes)

				node = tag_begin(tag)

				yield node if block_given?

				tag_end(tag)
			end

			def tag_complete(tag, node = nil)
				node ||= lookup_tag(tag)

				if node
					tag_begin(tag, node)
					tag_end(tag)
				else
					current.tag_complete(tag)
				end
			end

			def tag_begin(tag, node = nil)
				node ||= lookup_tag(tag)

				if node
					state = State.new(tag, node)
					@begin_tags << state

					node.tag_begin(self, state) if node.respond_to?(:tag_begin)

					return node
				end

				current.tag_begin(tag)

				return nil
			end
			
			def write(string)
				current.write(string)
			end
			
			alias cdata write

			def text(string)
				current.text(string)
			end

			def tag_end(tag = nil)
				# Get the current tag which we are completing/ending:
				top = current
				
				if top.tags.empty?
					node = top.node
					node.tag_end(self, top) if node.respond_to?(:tag_end)

					@end_tags << top
					buffer = top.call(self)

					@begin_tags.pop
					@end_tags.pop

					if current
						current.write(buffer)
					end

					return buffer
				else
					current.tag_end(tag)
				end

				return nil
			end
			
			def render_node(node, attributes = {})
				@begin_tags << State.new(nil, node, attributes)

				return tag_end
			end

			# Maps a tag to a node instance by asking the current node to lookup the tag name. This function is called for each tag and thus heavily affects performance.
			# @return [Node] The node for the given tag.
			def lookup_tag(tag)
				# result = tag
				# 
				# # This loop works from inner to outer tags, and updates the tag we are currently searching for based on any overrides:
				# @begin_tags.reverse_each do |state|
				# 	result = state.lookup(result)
				# 	
				# 	return result if result.is_a?(Node)
				# end
				
				# This loop looks up a tag by asking the most embedded node to look it up based on tag name. This almost always only evaluates the top state:
				@end_tags.reverse_each do |state|
					return state.node.lookup_tag(tag) if state.node.respond_to?(:lookup_tag)
				end
				
				return nil
			end
			
			# The current tag being processed/rendered. Prefer to access state directly.
			def current
				@begin_tags.last
			end

			# The content of the node
			def content
				@end_tags.last.content
			end

			def parent
				@end_tags[-2]
			end

			def first
				@begin_tags.first
			end
		end
		
		# The state of a single tag being rendered within a document instance.
		class Document::State
			def initialize(tag, node, attributes = tag.to_hash)
				@tag = tag
				@node = node
				@attributes = attributes
				
				@buffer = Trenni::MarkupString.new.force_encoding(Encoding::UTF_8)
				@content = nil
				
				@deferred = []
				
				@tags = []
			end

			attr :attributes
			attr :content
			attr :node
			attr :tags

			attr :deferred

			def defer(value = nil, &block)
				@deferred << block
				
				Tag.closed(DEFERRED_TAG_NAME, :id => @deferred.size - 1)
			end
			
			def [](key)
				@attributes[key]
			end

			def call(document)
				@content = @buffer
				@buffer = Trenni::MarkupString.new.force_encoding(Encoding::UTF_8)
				
				if node.respond_to? :call
					node.call(document, self)
				else
					document.parse_markup(@content)
				end
				
				return @buffer
			end

			def write(string)
				@buffer << string
			end

			def text(string)
				@buffer << Trenni::Markup.escape(string)
			end

			def tag_complete(tag)
				tag.write(@buffer)
			end

			def tag_begin(tag)
				@tags << tag
				tag.write_opening_tag(@buffer)
			end

			def tag_end(tag)
				raise UnbalancedTagError(tag) unless @tags.pop.name == tag.name
				tag.write_closing_tag(@buffer)
			end
		end
	end
end
