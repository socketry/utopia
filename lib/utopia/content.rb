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
require_relative 'localization'

require_relative 'content/node'
require_relative 'content/processor'

require 'trenni/template'

require 'concurrent/map'

module Utopia
	class Content
		INDEX = 'index'.freeze
		
		def initialize(app, **options)
			@app = app
			
			@root = File.expand_path(options[:root] || Utopia::default_root)
			
			if options[:cache_templates]
				@template_cache = Concurrent::Map.new
			else
				@template_cache = nil
			end
			
			@tags = options.fetch(:tags, {})
			
			self.freeze
		end

		def freeze
			@root.freeze
			@tags.freeze
			
			super
		end

		attr :root

		def fetch_xml(path)
			if @template_cache
				@template_cache.fetch_or_store(path.to_s) do
					Trenni::Template.load(path)
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
			
			if String === name && name.index('/')
				name = Path.create(name)
			end
			
			if Path === name
				name = parent_path + name
				name_path = name.components.dup
				name_path[-1] += XNODE_EXTENSION
			else
				name_path = name + XNODE_EXTENSION
			end

			parent_path.ascend do |dir|
				tag_path = File.join(root, dir.components, name_path)

				if File.exist? tag_path
					return Node.new(self, dir + name, parent_path + name, tag_path)
				end

				if String === name_path
					tag_path = File.join(root, dir.components, '_' + name_path)

					if File.exist? tag_path
						return Node.new(self, dir + name, parent_path + name, tag_path)
					end
				end
			end
			
			return nil
		end
		
		# The request_path is an absolute uri path, e.g. /foo/bar. If an xnode file exists on disk for this exact path, it is instantiated, otherwise nil.
		def lookup_node(request_path)
			name = request_path.last
			name_xnode = name.to_s + XNODE_EXTENSION

			node_path = File.join(@root, request_path.dirname.components, name_xnode)

			if File.exist? node_path
				return Node.new(self, request_path.dirname + name, request_path, node_path)
			end

			return nil
		end

		def call(env)
			request = Rack::Request.new(env)
			path = Path.create(request.path_info)
			
			# Check if the request is to a non-specific index. This only works for requests with a given name:
			basename = path.basename
			directory_path = File.join(@root, path.dirname.components, basename.name)

			# If the request for /foo/bar{extensions} is actually a directory, rewrite it to /foo/bar/index{extensions}:
			if File.directory? directory_path
				index_path = [basename.name, basename.rename(INDEX)]
				
				return [307, {HTTP::LOCATION => path.dirname.join(index_path).to_s}, []]
			end

			locale = env[Localization::CURRENT_LOCALE_KEY]
			if link = Links.for(@root, path, locale)
				if link.path and node = lookup_node(link.path)
					response = Rack::Response.new
					
					attributes = request.env.fetch(VARIABLES_KEY, {}).to_hash
					
					node.process!(request, response, attributes)
					
					return response.finish
				elsif redirect_uri = link[:uri]
					return [307, {HTTP::LOCATION => redirect_uri}, []]
				end
			end
			
			return @app.call(env)
		end
	end
end
