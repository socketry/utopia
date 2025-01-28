# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2009-2025, by Samuel Williams.

require_relative "middleware"
require_relative "localization"

require_relative "content/links"
require_relative "content/node"
require_relative "content/markup"
require_relative "content/tags"

require "xrb/template"

require "concurrent/map"

require "traces/provider"

module Utopia
	# A middleware which serves dynamically generated content based on markup files.
	class Content
		CONTENT_NAMESPACE = "content".freeze
		UTOPIA_NAMESPACE = "utopia".freeze
		DEFERRED_TAG_NAME = "utopia:deferred".freeze
		CONTENT_TAG_NAME = "utopia:content".freeze
		
		# @param root [String] The content root where pages will be generated from.
		# @param namespaces [Hash<String,Library>] Tag namespaces for dynamic tag lookup.
		def initialize(app, root: Utopia::default_root, namespaces: {})
			@app = app
			@root = root
			
			@template_cache = Concurrent::Map.new
			@node_cache = Concurrent::Map.new
			
			@links = Links.new(@root)
			
			@namespaces = namespaces
			
			# Default content namespace for dynamic path based lookup:
			@namespaces[CONTENT_NAMESPACE] ||= self.method(:content_tag)
			
			# The core namespace for utopia specific functionality:
			@namespaces[UTOPIA_NAMESPACE] ||= Tags
		end
		
		def freeze
			return self if frozen?
			
			@root.freeze
			@namespaces.values.each(&:freeze)
			@namespaces.freeze
			
			super
		end
		
		attr :root
		
		# TODO we should remove this method and expose `@links` directly.
		def links(path, **options)
			@links.index(path, **options)
		end
		
		def fetch_template(path)
			@template_cache.fetch_or_store(path.to_s) do
				XRB::Template.load_file(path)
			end
		end
		
		# Look up a named tag such as `<entry />` or `<content:page>...`
		def lookup_tag(qualified_name, node)
			namespace, name = XRB::Tag.split(qualified_name)
			
			if library = @namespaces[namespace]
				library.call(name, node)
			end
		end
		
		# @param path [Path] the request path is an absolute uri path, e.g. `/foo/bar`. If an xnode file exists on disk for this exact path, it is instantiated, otherwise nil.
		def lookup_node(path, locale = nil)
			resolve_link(
				@links.for(path, locale)
			)
		end
		
		def resolve_link(link)
			if full_path = link&.full_path(@root)
				if File.exist?(full_path)
					return Node.new(self, link.path, link.path, full_path)
				end
			end
		end
		
		def respond(link, request)
			if node = resolve_link(link)
				attributes = request.env.fetch(VARIABLES_KEY, {}).to_hash
				
				return node.process!(request, attributes)
			elsif redirect_uri = link[:uri]
				return [307, {HTTP::LOCATION => redirect_uri}, []]
			end
		end
		
		def call(env)
			request = Rack::Request.new(env)
			path = Path.create(request.path_info)
			
			# Check if the request is to a non-specific index. This only works for requests with a given name:
			basename = path.basename
			directory_path = File.join(@root, path.dirname.components, basename)
			
			# If the request for /foo/bar is actually a directory, rewrite it to /foo/bar/index:
			if File.directory? directory_path
				index_path = [basename, INDEX]
				
				return [307, {HTTP::LOCATION => path.dirname.join(index_path).to_s}, []]
			end
			
			locale = env[Localization::CURRENT_LOCALE_KEY]
			if link = @links.for(path, locale)
				if response = self.respond(link, request)
					return response
				end
			end
			
			return @app.call(env)
		end
		
		private
		
		def lookup_content(name, parent_path)
			if String === name && name.index("/")
				name = Path.create(name)
			end
			
			if Path === name
				name = parent_path + name
				name_path = name.components.dup
				name_path[-1] += XNODE_EXTENSION
			else
				name_path = name + XNODE_EXTENSION
			end
			
			components = parent_path.components.dup
			
			while components.any?
				tag_path = File.join(@root, components, name_path)
				
				if File.exist? tag_path
					return Node.new(self, Path[components] + name, parent_path + name, tag_path)
				end
				
				if String === name_path
					tag_path = File.join(@root, components, "_" + name_path)
					
					if File.exist? tag_path
						return Node.new(self, Path[components] + name, parent_path + name, tag_path)
					end
				end
				
				components.pop
			end
			
			return nil
		end
		
		def content_tag(name, node)
			full_path = node.parent_path + name
			
			name = full_path.pop
			
			# If the current node is called 'foo', we can't lookup 'foo' in the current directory or we will have infinite recursion.
			while full_path.last == name
				full_path.pop
			end
			
			cache_key = full_path + name
			
			@node_cache.fetch_or_store(cache_key) do
				lookup_content(name, full_path)
			end
		end
	end
	
	Traces::Provider(Content) do
		def respond(link, request)
			attributes = {
				"link.key" => link.key,
				"link.href" => link.href
			}
			
			Traces.trace("utopia.content.respond", attributes: attributes) {super}
		end
	end
end
