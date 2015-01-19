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

require_relative 'middleware'

require_relative 'content/node'
require_relative 'content/processor'

require 'trenni/template'

module Utopia
	class Content
		def initialize(app, options = {})
			@app = app

			@root = File.expand_path(options[:root] || Utopia::default_root)

			@templates = options[:cache_templates] ? {} : nil

			@tags = options.fetch(:tags, {})
		end

		attr :root
		attr :passthrough

		def fetch_xml(path)
			if @templates
				@templates.fetch(path) do |key|
					@templates[key] = Trenni::Template.load(path)
				end
			else
				Trenni::Template.load(path)
			end
		end

		# Look up a named tag such as <entry />
		def lookup_tag(name, parent_path)
			if @tags.key? name
				return @tags[name]
			end
			
			if String === name && name.index("/")
				name = Path.create(name)
			end
			
			if Path === name
				name = parent_path + name
				name_path = name.components.dup
				name_path[-1] += ".xnode"
			else
				name_path = name + ".xnode"
			end

			parent_path.ascend do |dir|
				tag_path = File.join(root, dir.components, name_path)

				if File.exist? tag_path
					return Node.new(self, dir + name, parent_path + name, tag_path)
				end

				if String === name_path
					tag_path = File.join(root, dir.components, "_" + name_path)

					if File.exist? tag_path
						return Node.new(self, dir + name, parent_path + name, tag_path)
					end
				end
			end
			
			return nil
		end

		def lookup_node(request_path)
			name = request_path.basename
			name_xnode = name + ".xnode"

			node_path = File.join(@root, request_path.dirname.components, name_xnode)

			if File.exist? node_path
				return Node.new(self, request_path.dirname + name, request_path, node_path)
			end

			return nil
		end

		def call(env)
			request = Rack::Request.new(env)
			path = Path.create(request.path_info).to_absolute

			# Check if the request is to a non-specific index. This only works for requests with a given name:
			name, extensions = path.basename_parts
			directory_path = File.join(@root, path.dirname.components, name)

			if File.directory? directory_path
				index_path = [name, Path.join_name("index", extensions)]
				
				return [307, {"Location" => path.dirname.join(index_path).to_s}, []]
			end

			# Otherwise look up the node
			node = lookup_node(path)

			if node
				if request.head?
					return [200, {}, []]
				else
					response = Rack::Response.new
					
					attributes = {}
					
					if request.controller
						attributes = request.controller.to_hash
					end
					
					node.process!(request, response, attributes)
					
					return response.finish
				end
			else
				return @app.call(env)
			end
		end
	end
end
