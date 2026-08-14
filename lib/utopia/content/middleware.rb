# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2025-2026, by Samuel Williams.

require_relative "../middleware"
require_relative "../localization/resolver"
require_relative "../request"
require_relative "../response"
require_relative "../controller/variables"

require_relative "links"
require_relative "node"
require_relative "markup"
require_relative "tags"

require "xrb/template"
require "concurrent/map"
require "traces/provider"

module Utopia
	module Content
		# A middleware which serves dynamically generated content based on markup files.
		class Middleware < Protocol::HTTP::Middleware
			include Localization::Resolver
			
			CONTENT_NAMESPACE = "content".freeze
			RELATIVE_NAMESPACE = "relative".freeze
			UTOPIA_NAMESPACE = "utopia".freeze
			CONTENT_TAG_NAME = "utopia:content".freeze
			
			# @param root [String] The content root where pages will be generated from.
			# @param namespaces [Hash<String,Library>] Tag namespaces for dynamic tag lookup.
			def initialize(app, root: Utopia::default_root, namespaces: {})
				super(app)
				
				@root = root
				
				@template_cache = Concurrent::Map.new
				@node_cache = Concurrent::Map.new
				
				@links = Links.new(@root)
				
				@namespaces = namespaces
				
				# Default content namespace for dynamic path based lookup:
				@namespaces[CONTENT_NAMESPACE] ||= self.method(:content_tag)
				
				# Resolve content relative to the logical invocation path:
				@namespaces[RELATIVE_NAMESPACE] ||= self.method(:relative_tag)
				
				# The core namespace for utopia specific functionality:
				@namespaces[UTOPIA_NAMESPACE] ||= Tags
			end
			
			# Freeze this object and its internal state.
			# @returns [self] This object.
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
			
			# Load and cache a content template.
			# @parameter path [Utopia::Path | String] The path.
			# @returns [XRB::Template] The parsed template.
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
			
			# Resolve a link to an existing content node.
			# @parameter link [Utopia::Content::Link] The content link.
			# @returns [Node | Nil] The content node when its backing file exists.
			def resolve_link(link)
				if full_path = link&.full_path(@root)
					if File.exist?(full_path)
						return Node.new(self, link.path, link.path, full_path)
					end
				end
			end
			
			# Respond.
			# @parameter link [Utopia::Content::Link] The content link.
			# @parameter request [Utopia::Request] The application request.
			# @parameter localization [Utopia::Localization::Preferences | Nil] The selected localization.
			# @returns [Protocol::HTTP::Response] The response.
			def respond(link, request, localization: request.localization)
				if node = resolve_link(link)
					attributes = request.variables&.to_hash || {}
					
					return node.process!(request, attributes, localization: localization)
				elsif redirect_uri = link[:uri]
					return Utopia::Response[307, {HTTP::LOCATION => redirect_uri}, []]
				end
			end
			
			# Serve or redirect filesystem-backed content, otherwise invoke the application.
			# @parameter request [Utopia::Request] The request.
			# @returns [Protocol::HTTP::Response] The content, redirect, or downstream response.
			def call(request)
				path = request.path
				
				# Check if the request is to a non-specific index. This only works for requests with a given name:
				basename = path.basename
				directory_path = File.join(@root, path.dirname.components, basename)
				
				# If the request for /foo/bar is actually a directory, rewrite it to /foo/bar/index:
				if File.directory? directory_path
					index_path = [basename, INDEX]
					location = path.dirname.join(index_path).to_url_path.encoded
					
					return Utopia::Response[307, {HTTP::LOCATION => location}, []]
				end
				
				response = resolve_localized(request) do |localization|
					locale = localization&.locale
					
					if link = @links.for(path, locale, fallback: false)
						self.respond(link, request, localization: localization)
					end
				end
				
				if response
					return response
				end
				
				return @delegate.call(request)
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
			
			def content_tag(name, node, parent_path: node.parent_path)
				full_path = parent_path + name
				
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
			
			def relative_tag(name, node)
				content_tag(name, node, parent_path: node.request_path.dirname)
			end
		end
		
		Traces::Provider(Middleware) do
			def respond(link, request, localization: request.localization)
				attributes = {
					"link.key" => link.key,
					"link.href" => link.href,
					"link.locale" => localization&.locale,
				}
				
				Traces.trace("utopia.content.middleware.respond", attributes: attributes){super}
			end
		end
	end
end
