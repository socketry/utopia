
require 'set'

require 'utopia/xnode'
require 'utopia/link'

module Utopia

	module Middleware
		class Content
			HTML_TAGS = Set.new(%w{html head body link a p h1 h2 h3 h4 h5 h6 div span ul li ol dl})

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
						@overrides = nil

						@tags = []
						@attributes = tag.to_hash

						@content = nil
					end

					attr :attributes
					attr :overrides
					attr :content
					attr :node
					attr :tags

					def [](key)
						@attributes[key.to_s]
					end

					def call(transaction)
						if node.respond_to? :call
							@content = @buffer.string
							@buffer = StringIO.new

							node.call(transaction, self)

							return @buffer.string
						end
					end

					def lookup(tag)
						if overrides
							override = @overrides[tag.name]

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
						tag.write_open_html(@buffer)
						tag.write_close_html(@buffer)
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
				attr :begin_tags
				attr :end_tags

				def attributes
					return current.attributes
				end

				def current
					@begin_tags.last
				end

				def content
					@end_tags.last.content
				end

				def parent
					@begin_tags[-2]
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
						tag_begin(tag, node)
						tag_end(tag)
					end
				end

				def tag_begin(tag, node = nil)
					# LOG.debug("tag_begin: #{tag}")
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
					# LOG.debug("cdata: #{text}")
					current.cdata(text)
				end

				def tag_end(tag = nil)
					top = current

					if top.tags.empty?
						# LOG.debug("tag_end: #{top.inspect}")

						if top.node.respond_to? :tag_end
							top.node.tag_end(self, top)
						end

						@end_tags << top
						buffer = top.call(self)

						@begin_tags.pop
						@end_tags.pop

						# LOG.debug("buffer = #{buffer}")

						if current
							current.markup(buffer)
						end

						return buffer
					else
						# LOG.debug("tag_end: #{tag}")
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

				def local_path(path, base = nil)
					path = Path.create(path)
					
					if path.absolute?
						return File.join(@controller.root, path.components)
					else
						base ||= uri_path.dirname
						return File.join(@controller.root, (base + path).components)
					end
				end

				def lookup(tag)
					return @controller.lookup_tag(tag.name, parent_path)
				end

				def parent_path
					uri_path.dirname
				end

				def links(path, options = {}, &block)
					path = uri_path.dirname + Path.create(path)
					links = Links.index(@controller.root, path, options)
					
					if block_given?
						links.each &block
					else
						links
					end
				end

				def related_links
					name = uri_path.basename.split(".").first
					links = Links.index(@controller.root, uri_path.dirname, :name => name, :indices => true)
				end

				def call(transaction, state)
					xml_data = @controller.fetch_xml(@file_path).result(transaction.binding, @file_path)
					
					transaction.parse_xml(xml_data)
				end

				def process!(request, response)
					transaction = Transaction.new(request, response)
					response.body = [transaction.render_node(self)]
				end
			end
			
		end
	end
end