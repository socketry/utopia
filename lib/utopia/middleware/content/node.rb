#	This file is part of the "Utopia Framework" project, and is released under the MIT license.
#	Copyright 2010 Samuel Williams. All rights reserved.
#	See <utopia.rb> for licensing details.

require 'set'

require 'utopia/xnode'
require 'utopia/link'

module Utopia

	module Middleware
		class Content
			class UnbalancedTagError < StandardError
				def initialize(tag)
					@tag = tag
					
					super("Unbalanced tag #{tag.name}")
				end
				
				attr :tag
			end

			# Nodes typically represent XNODE files on the disk.
			# You can get a list of Links from a current directory. This comprises of all
			# files ending in ".xnode".

			class Transaction
				class State
					def initialize(tag, node)
						@node = node

						@buffer = StringIO.new
						@overrides = {}

						@tags = []
						@attributes = tag.to_hash

						@content = nil
						@deferred = []
					end

					attr :attributes
					attr :overrides
					attr :content
					attr :node
					attr :tags

					attr :deferred

					def defer(&block)
						@deferred << block
						
						Tag.closed("deferred", :id => @deferred.size - 1).to_html
					end

					def [](key)
						@attributes[key.to_s]
					end

					def call(transaction)
						@content = @buffer.string
						@buffer = StringIO.new
						
						if node.respond_to? :call
							node.call(transaction, self)
						else
							transaction.parse_xml(@content)
						end

						return @buffer.string
					end

					def lookup(tag)
						if override = @overrides[tag.name]
							if override.respond_to? :call
								return override.call(tag)
							elsif String === override
								return Tag.new(override, tag.attributes)
							else
								return override
							end
						else
							return tag
						end
					end

					def cdata(text)
						@buffer.write(text)
					end

					def markup(text)
						cdata(text)
					end

					def tag_complete(tag)
						tag.write_full_html(@buffer)
					end

					def tag_begin(tag)
						@tags << tag
						tag.write_open_html(@buffer)
					end

					def tag_end(tag)
						raise UnbalancedTagError(tag) unless @tags.pop.name == tag.name

						tag.write_close_html(@buffer)
					end
				end

				def initialize(request, response)
					@begin_tags = []
					@end_tags = []

					@request = request
					@response = response
				end

				def binding
					super
				end

				def parse_xml(xml_data)
					XNode::Processor.new(xml_data, self).parse
				end

				attr :request
				attr :response
				
				# Begin tags represents a list from outer to inner most tag.
				# At any point in parsing xml, begin_tags is a list of the inner most tag,
				# then the next outer tag, etc. This list is used for doing dependent lookups.
				attr :begin_tags
				
				# End tags represents a list of execution order. This is the order that end tags
				# have appeared when evaluating nodes.
				attr :end_tags

				def attributes
					return current.attributes
				end

				def current
					@begin_tags[-1]
				end

				def content
					@end_tags[-1].content
				end

				def parent
					end_tags[-2]
				end

				def first
					@begin_tags[0]
				end

				def tag(name, attributes, &block)
					tag = Tag.new(name, attributes)

					node = tag_begin(tag)

					yield node if block_given?

					tag_end(tag)
				end

				def tag_complete(tag, node = nil)
					if tag.name == "content"
						current.markup(content)
					else
						node ||= lookup(tag)

						if node
							tag_begin(tag, node)
							tag_end(tag)
						else
							current.tag_complete(tag)
						end
					end
				end

				def tag_begin(tag, node = nil)
					node ||= lookup(tag)

					if node
						state = State.new(tag, node)
						@begin_tags << state

						if node.respond_to? :tag_begin
							node.tag_begin(self, state)
						end

						return node
					end

					current.tag_begin(tag)

					return nil
				end

				def cdata(text)
					current.cdata(text)
				end

				def tag_end(tag = nil)
					top = current

					if top.tags.empty?
						if top.node.respond_to? :tag_end
							top.node.tag_end(self, top)
						end

						@end_tags << top
						buffer = top.call(self)

						@begin_tags.pop
						@end_tags.pop

						if current
							current.markup(buffer)
						end

						return buffer
					else
						current.tag_end(tag)
					end
					
					return nil
				end

				def render_node(node, attributes = {})
					state = State.new(attributes, node)
					@begin_tags << state
					
					return tag_end
				end

				def lookup(tag)
					result = tag
					node = nil
					
					@begin_tags.reverse_each do |state|
						result = state.lookup(result)
						
						node ||= state.node if state.node.respond_to? :lookup

						return result if Node === result
					end
					
					@end_tags.reverse_each do |state|
						return state.node.lookup(result) if state.node.respond_to? :lookup
					end
					
					return nil
				end

				def method_missing(name, *args)
					@begin_tags.reverse_each do |state|
						if state.node.respond_to? name
							return state.node.send(name, *args)
						end
					end

					super
				end
			end

			class Node
				def initialize(controller, uri_path, request_path, file_path)
					@controller = controller

					@uri_path = uri_path
					@request_path = request_path
					@file_path = file_path
				end

				attr :request_path
				attr :uri_path
				attr :file_path

				def link
					return Link.new(:file, uri_path)
				end

				def lookup_node(path)
					@controller.lookup_node(path)
				end

				def local_path(path = ".", base = nil)
					path = Path.create(path)
					root = Pathname.new(@controller.root)
					
					if path.absolute?
						return root.join(*path.components)
					else
						base ||= uri_path.dirname
						return root.join(*(base + path).components)
					end
				end

				def lookup(tag)
					from_path = parent_path
					
					# If the current node is called 'foo', we can't lookup 'foo' in the current directory or we will likely have infinite recursion.
					if tag.name == @uri_path.basename
						from_path = from_path.dirname
					end
					
					return @controller.lookup_tag(tag.name, from_path)
				end

				def parent_path
					uri_path.dirname
				end

				def links(path = ".", options = {}, &block)
					path = uri_path.dirname + Path.create(path)
					links = Links.index(@controller.root, path, options)
					
					if block_given?
						links.each &block
					else
						links
					end
				end

				def related_links
					name = @uri_path.basename.split(".").first
					links = Links.index(@controller.root, uri_path.dirname, :name => name, :indices => true)
				end

				def siblings_path
					name = @uri_path.basename.split(".").first
					
					if name == "index"
						@uri_path.dirname(2)
					else
						@uri_path.dirname
					end
				end

				def sibling_links(options = {})
					return Links.index(@controller.root, siblings_path, options)
				end

				def call(transaction, state)
					xml_data = @controller.fetch_xml(@file_path).result(transaction.binding)
					
					transaction.parse_xml(xml_data)
				end

				def process!(request, response)
					transaction = Transaction.new(request, response)
					response.write(transaction.render_node(self))
				end
			end
			
		end
	end
end