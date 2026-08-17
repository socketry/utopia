# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2009-2026, by Samuel Williams.
# Copyright, 2015, by Huba Nagy.

require_relative "markup"
require_relative "links"

require_relative "document"

require "pathname"

module Utopia
	module Content
		# Represents an immutable node within the content hierarchy.
		class Node
			# Initialize a node within the filesystem-backed content hierarchy.
			# @parameter controller [Utopia::Controller::Base] The controller instance.
			# @parameter uri_path [Utopia::Path | String] The uri path.
			# @parameter request_path [Utopia::Path | String] The request path.
			# @parameter file_path [String] The filesystem path.
			def initialize(controller, uri_path, request_path, file_path)
				@controller = controller
				
				@uri_path = uri_path
				@request_path = request_path
				@file_path = file_path
			end
			
			attr :request_path
			attr :uri_path
			attr :file_path
			
			# Return the node's URI basename.
			# @returns [String] The node name.
			def name
				@uri_path.basename
			end
			
			# Resolve another node relative to this node's parent.
			# @parameter path [Utopia::Path | String] The path.
			# @returns [Node | Nil] The resolved node.
			def lookup_node(path)
				@controller.lookup_node(parent_path + Path[path])
			end
			
			# Resolve a content path beneath the controller root.
			# @parameter path [Utopia::Path | String] The path.
			# @returns [Pathname] The local filesystem path.
			def local_path(path = ".", base = nil)
				path = Path[path]
				
				root = Pathname.new(@controller.root)
				
				if path.absolute?
					return root.join(*path.components)
				else
					base ||= uri_path.dirname
					return root.join(*(base + path).components)
				end
			end
			
			# Resolve a path relative to this node's containing URI path.
			# @parameter path [Utopia::Path | String] The path.
			# @returns [Path] The resolved content path.
			def relative_path(path = ".")
				path = Path[path]
				base = uri_path.dirname
				
				return base + path
			end
			
			# Return this node's containing URI path.
			# @returns [Path] The parent URI path.
			def parent_path
				@uri_path.dirname
			end
			
			# Enumerate or return links relative to this node.
			# @parameter path [Utopia::Path | String] The path.
			# @yields {|link| ...} Each matching link when a block is given.
			# @returns [Array(Link)] The matching links.
			def links(path = ".", **options, &block)
				path = uri_path.dirname + Path[path]
				
				links = @controller.links.index(path, **options)
				
				if block_given?
					links.each(&block)
				else
					links
				end
			end
			
			# Return localized and indexed variants related to this node.
			# @returns [Array(Link)] The related links.
			def related_links
				@controller.links.index(@uri_path.dirname, name: @uri_path.basename, indices: true)
			end
			
			# Return the directory whose links are siblings of this node.
			# @returns [Path] The sibling directory path.
			def siblings_path
				if @uri_path.basename == INDEX
					@uri_path.dirname(2)
				else
					@uri_path.dirname
				end
			end
			
			# Return links that are siblings of this node.
			# @parameter options [Hash] The options.
			# @returns [Array(Link)] The sibling links.
			def sibling_links(**options)
				return @controller.links.index(siblings_path, **options)
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
			
			# Process the request and return the resulting response.
			# @parameter request [Utopia::Request] The application request.
			# @parameter attributes [Hash] The attributes.
			# @parameter localization [Utopia::Localization::Preferences | Nil] The selected localization.
			# @returns [Protocol::HTTP::Response] The response.
			def process!(request, attributes = {}, localization: request&.localization)
				Document.render(self, request, attributes, localization: localization).to_response
			end
			
			# This is a special context in which a limited set of well defined methods are exposed in the content view.
			Context = Struct.new(:document, :state) do
				# Render or defer a partial content block.
				# @parameter arguments [Array] The arguments.
				# @yields {|document| ...} Deferred content, when a block is given.
				# @returns [String] The deferred-content marker.
				def partial(*arguments, &block)
					if block_given?
						state.defer(&block)
					else
						state.defer do |document|
							document.tag(*arguments)
						end
					end
				end
				
				alias deferred_tag partial
				
				# Return the controller associated with the document.
				# @returns [Controller::Variables | Nil] The current controller variables.
				def controller
					document.controller
				end
				
				# Return the document's localization preferences.
				# @returns [Localization::Preferences | Nil] The localization preferences.
				def localization
					document.localization
				end
				
				# Return the application request being rendered.
				# @returns [Utopia::Request] The request.
				def request
					document.request
				end
				
				# Return the document response being rendered.
				# @returns [Document] The document response.
				def response
					document
				end
				
				# Return attributes for the current rendering state.
				# @returns [Hash] The current attributes.
				def attributes
					state.attributes
				end
				
				# Fetch an attribute from the current state or document defaults.
				# @parameter key [String | Symbol] The lookup key.
				# @returns [Object | Nil] The state attribute, falling back to the document attribute.
				def [] key
					state.attributes.fetch(key){document.attributes[key]}
				end
				
				alias current state
				
				# Return the captured content of the current node.
				# @returns [String] The captured content.
				def content
					document.content
				end
				
				# Return the enclosing rendering state.
				# @returns [Builder | Nil] The parent rendering state.
				def parent
					document.parent
				end
				
				# Return the first rendering state in the document.
				# @returns [Builder | Nil] The first rendering state.
				def first
					document.first
				end
				
				# Return or enumerate links relative to the current node.
				# @parameter arguments [Array] The arguments.
				# @parameter options [Hash] The options.
				# @yields {|link| ...} Each matching link when a block is given.
				# @returns [Array(Link)] The matching links.
				def links(*arguments, **options, &block)
					state.node.links(*arguments, **options, &block)
				end
			end
		end
	end
end
