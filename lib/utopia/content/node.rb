# frozen_string_literal: true

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

require_relative 'markup'
require_relative 'links'

require_relative 'document'

require 'pathname'

module Utopia
	class Content
		# Represents an immutable node within the content hierarchy.
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
			
			def name
				@uri_path.basename
			end
			
			def lookup_node(path)
				@controller.lookup_node(parent_path + Path[path])
			end
			
			def local_path(path = '.', base = nil)
				path = Path[path]
				
				root = Pathname.new(@controller.root)
				
				if path.absolute?
					return root.join(*path.components)
				else
					base ||= uri_path.dirname
					return root.join(*(base + path).components)
				end
			end
			
			def relative_path(path = '.')
				path = Path[path]
				base = uri_path.dirname
				
				return base + path
			end
			
			def parent_path
				@uri_path.dirname
			end
			
			def links(path = '.', **options, &block)
				path = uri_path.dirname + Path[path]
				
				links = @controller.links(path, **options)
				
				if block_given?
					links.each(&block)
				else
					links
				end
			end
			
			def related_links
				@controller.links(@uri_path.dirname, name: @uri_path.basename, indices: true)
			end
			
			def siblings_path
				if @uri_path.basename == INDEX
					@uri_path.dirname(2)
				else
					@uri_path.dirname
				end
			end
			
			def sibling_links(**options)
				return @controller.links(siblings_path, **options)
			end
			
			# Lookup the given tag which is being rendered within the given node. Invoked by {Document}.
			# @return [Node] The node which will be used to render the tag.
			def lookup_tag(tag)
				return @controller.lookup_tag(tag.name, self)
			end
			
			# Invoked when the node is being rendered by {Document}.
			def call(document, state)
				# Load the template:
				template = @controller.fetch_template(@file_path)
				
				# Evaluate the template/code:
				context = Context.new(document, state)
				markup = template.to_buffer(context)
				
				# Render the resulting markup into the document:
				document.parse_markup(markup)
			end
			
			def process!(request, attributes = {})
				Document.render(self, request, attributes).to_a
			end
			
			# This is a special context in which a limited set of well defined methods are exposed in the content view.
			Context = Struct.new(:document, :state) do
				def partial(*args, &block)
					if block_given?
						state.defer(&block)
					else
						state.defer do |document|
							document.tag(*args)
						end
					end
				end
				
				alias deferred_tag partial
				
				def controller
					document.controller
				end
				
				def localization
					document.localization
				end
				
				def request
					document.request
				end
				
				def response
					document
				end
				
				def attributes
					state.attributes
				end
				
				def [] key
					state.attributes.fetch(key) {document.attributes[key]}
				end
				
				alias current state
				
				def content
					document.content
				end
				
				def parent
					document.parent
				end
				
				def first
					document.first
				end
				
				def links(*arguments, **options, &block)
					state.node.links(*arguments, **options, &block)
				end
			end
		end
	end
end