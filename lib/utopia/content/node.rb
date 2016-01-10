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

require_relative 'processor'
require_relative 'links'
require_relative 'transaction'

require 'pathname'

module Utopia
	class Content
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

			def lookup(tag)
				from_path = parent_path
				
				# If the current node is called 'foo', we can't lookup 'foo' in the current directory or we will have infinite recursion.
				if tag.name == @uri_path.basename
					from_path = from_path.dirname
				end
				
				return @controller.lookup_tag(tag.name, from_path)
			end

			def parent_path
				uri_path.dirname
			end

			def links(path = '.', **options, &block)
				path = uri_path.dirname + Path[path]
				links = Links.index(@controller.root, path, options)
				
				if block_given?
					links.each(&block)
				else
					links
				end
			end

			def related_links
				name = @uri_path.last.split('.', 2).first
				
				return Links.index(@controller.root, uri_path.dirname, :name => name, :indices => true)
			end

			def siblings_path
				name = @uri_path.last.split('.', 2).first
				
				if name == INDEX
					@uri_path.dirname(2)
				else
					@uri_path.dirname
				end
			end

			def sibling_links(**options)
				return Links.index(@controller.root, siblings_path, options)
			end

			def call(transaction, state)
				xml_data = @controller.fetch_xml(@file_path).evaluate(transaction)
				
				transaction.parse_xml(xml_data)
			end

			def process!(request, response, attributes = {})
				transaction = Transaction.new(request, response)
				response.write(transaction.render_node(self, attributes))
			end
		end
	end
end
