#	This file is part of the "Utopia Framework" project, and is released under the MIT license.
#	Copyright 2010 Samuel Williams. All rights reserved.
#	See <utopia.rb> for licensing details.

require 'utopia/middleware'
require 'utopia/link'
require 'utopia/path'
require 'utopia/tags'

require 'utopia/middleware/content/node'
require 'utopia/trenni'

module Utopia
	module Middleware
	
		class Content
			def initialize(app, options = {})
				@app = app

				@root = File.expand_path(options[:root] || Utopia::Middleware::default_root)
				
				LOG.info "** #{self.class.name}: Running in #{@root}"

				# Set to hash to enable caching
				@nodes = {}
				@files = nil

				@tags = options[:tags] || {}
			end

			attr :root
			attr :passthrough

			def fetch_xml(path)
				read_file = lambda { Trenni.new(File.read(path), path) }
				
				if @files
					@files.fetch(path) do
						@files[path] = read_file.call
					end
				else
					read_file.call
				end
			end

			# Look up a named tag such as <entry />
			def lookup_tag(name, parent_path)
				if @tags.key? name
					return @tags[name]
				elsif Utopia::Tags.all.key? name
					return Utopia::Tags.all[name]
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

				# Check if the request is to a non-specific index.
				name, extensions = path.basename.split(".", 2)
				directory_path = File.join(@root, path.dirname.components, name)

				if File.directory? directory_path
					if extensions
						index_path = [name, "index.#{extensions}"]
					else
						index_path = [name, "index"]
					end
					
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
end
