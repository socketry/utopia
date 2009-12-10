
require 'utopia/middleware'
require 'utopia/link'
require 'utopia/path'
require 'utopia/etanni'
require 'utopia/tags'

require 'utopia/middleware/content/node'

module Utopia
	module Middleware
	
		class Content
			def initialize(app, options = {})
				@app = app

				@root = File.expand_path(options[:root] || Utopia::Middleware::default_root)
				
				LOG.info "#{self.class.name}: Running in #{@root}"

				# Set to hash to enable caching
				@nodes = {}
				@files = nil

				@tags = options[:tags] || {}
			end

			attr :root
			attr :passthrough

			def fetch_xml(path)
				if @files
					@files.fetch(path) do
						@files[path] = Etanni.new(File.read(path))
					end
				else
					Etanni.new(File.read(path))
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
					return [307, {"Location" => path.dirname.join([name, "index.#{extensions}"]).to_s}, []]
				end

				# Otherwise look up the node
				node = lookup_node(path)

				if node
					if request.head?
						return [200, {}, []]
					else
						response = Rack::Response.new
						node.process!(request, response)
						return response.finish
					end
				else
					return @app.call(env)
				end
			end
		end
		
	end
end
