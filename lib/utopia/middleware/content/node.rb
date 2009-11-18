
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

			class Node
				class Transaction
					State = Struct.new(:node, :template, :attributes)

					def initialize(request, response)
						@stack = []
						@request = request
						@response = response
					end

					attr :request
					attr :response
					attr :stack

					def current
						@stack[-1]
					end

					def parent
						@stack[-2]
					end

					def first
						@stack[0]
					end

					def binding
						super
					end

					def attributes
						current.attributes
					end

					def [](key)
						attributes[key.to_s]
					end

					def content
						parent.template.inner
					end

					def render_tag(tag)
						if tag.name == "content"
							return content.to_html
						end

						node = lookup(tag.name)

						if node == nil
							tag.to_html
						else
							render_node(node, tag.attributes)
						end
					end

					def render_node(node, attributes = {})
						append(node) do
							current.attributes = attributes

							if node.respond_to? :call
								node.call(self)
							else
								node.process(self).content
							end
						end
					end

					def append(node, &block)
						begin
							@stack << Transaction::State.new(node, nil, nil)
							
							yield
						ensure
							@stack.pop
						end
					end

					def links(path, options = {}, &block)
						options = options.dup

						options[:locale] = request.current_locale if request.respond_to?(:current_locale)

						current.node.links(path, options, &block)
					end

					def method_missing(name, *args)
						@stack.reverse_each do |state|
							if state.node.respond_to? name
								return state.node.send(name, *args)
							end
						end
						
						super
					end
				end

				class Template
					def self.parse(transaction, xml_data, file_path, &block)
						template = Template.new(&block)
						transaction.current.template = template

						XNode::Processor.new(xml_data, template).parse

						if template.stack.size > 1
							LOG.error("While processing #{file_path}:")
							LOG.error("\tStack is not empty: \n#{YAML::dump(template.stack)}")
						end

						return template
					end

					def initialize(&block)
						@callback = Proc.new(&block)
						@stack = [Tag.new("root")]
					end

					attr :stack
					attr :inner

					def content
						@stack.last.to_s
					end

					def tag(name, value_attrs)
						@inner = Tag.new(name, value_attrs)
						text = @callback.call(self, @inner)

						append(text)
					end

					def tag_start(name, value_attrs)
						@stack << Tag.new(name, value_attrs)
					end

					def tag_end(name)
						@inner = @stack.pop

						if @inner.name != name
							raise UnbalancedTagError.new(@inner)
						end

						text = @callback.call(self, @inner)
						append(text)
					end

					def text(string)
						append(string)
					end

					def append(string)
						@stack.last.append(string)
					end

					def instruction(name, text)
					end

					def doctype(string)
						string.strip!
						append "<!DOCTYPE #{string}>"
					end
				end

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
					# metadata = Links.metadata(file_path.dirname)
					# info = metadata ? metadata[uri_path.basename] : {}

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

				def lookup(name)
					return @controller.lookup_tag(name, parent_path)
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

				public
				def process(transaction)
					xml_data = @controller.fetch_xml(@file_path).result(transaction.binding, @file_path)

					template = Template.parse(transaction, xml_data, @file_path) do |template, tag|
						transaction.render_tag(tag)
					end

					return template
				end

				def process!(request, response)
					# info = Links.metadata(File.dirname(file_path))
					
					transaction = Transaction.new(request, response)
					
					# Render body
					response.body = [transaction.render_node(self)]
				end
			end
			
		end
	end
end