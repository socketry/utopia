# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2025, by Samuel Williams.

require "json"
require "xrb"
require "protocol/url"

module Utopia
	# Represents an import map for JavaScript modules with support for URI and relative path resolution.
	# Import maps allow you to control how JavaScript imports are resolved, supporting both absolute
	# URLs and relative paths with proper context-aware resolution.
	#
	# The builder pattern supports nested base URIs that are properly resolved relative to parent bases.
	# All URL resolution follows RFC 3986 via the `protocol-url` gem.
	#
	# @example Basic usage with absolute URLs.
	# 	import_map = Utopia::ImportMap.build do |map|
	# 		map.import("react", "https://esm.sh/react@18")
	# 		map.import("@myapp/utils", "./js/utils.js", integrity: "sha384-...")
	# 	end
	# 	
	# 	puts import_map.to_html
	#
	# @example Using nested base URIs for different CDNs.
	# 	import_map = Utopia::ImportMap.build do |map|
	# 		# Imports without base
	# 		map.import("app", "/app.js")
	# 		
	# 		# CDN imports - base is set to jsdelivr
	# 		map.with(base: "https://cdn.jsdelivr.net/npm/") do |m|
	# 			m.import "lit", "lit@2.7.5/index.js"
	# 			m.import "lit/decorators.js", "lit@2.7.5/decorators.js"
	# 		end
	# 		
	# 		# Nested base combines with parent: "https://cdn.jsdelivr.net/npm/mermaid@10/"
	# 		map.with(base: "https://cdn.jsdelivr.net/npm/") do |m|
	# 			m.with(base: "mermaid@10/") do |nested|
	# 				nested.import "mermaid", "dist/mermaid.esm.min.mjs"
	# 			end
	# 		end
	# 	end
	#
	# @example Creating page-specific import maps with relative paths.
	# 	# Global import map with base: "/_components/"
	# 	global_map = Utopia::ImportMap.build(base: "/_components/") do |map|
	# 		map.import("button", "./button.js")
	# 	end
	# 	
	# 	# For a page at /foo/bar/, create a context-specific import map
	# 	page_map = global_map.relative_to("/foo/bar/")
	# 	# Base becomes: "../../_components/"
	# 	# button import resolves to: "../../_components/button.js"
	# 	
	# 	puts page_map.to_html
	class ImportMap
		# Builder class for constructing import maps with scoped base URIs.
		#
		# The builder supports nested `with(base:)` blocks where each base is resolved
		# relative to its parent base, following RFC 3986 URL resolution rules.
		#
		# @example Nested base resolution.
		# 	ImportMap.build do |map|
		# 		# No base - imports as-is
		# 		map.import("app", "/app.js")
		# 		
		# 		# Base: "https://cdn.example.com/"
		# 		map.with(base: "https://cdn.example.com/") do |cdn|
		# 			cdn.import("lib", "lib.js")  # => "https://cdn.example.com/lib.js"
		# 			
		# 			# Nested base: "https://cdn.example.com/" + "v2/" = "https://cdn.example.com/v2/"
		# 			cdn.with(base: "v2/") do |v2|
		# 				v2.import("new-lib", "lib.js")  # => "https://cdn.example.com/v2/lib.js"
		# 			end
		# 		end
		# 	end
		class Builder
			def self.build(import_map, **options, &block)
				builder = self.new(import_map, **options)
				
				if block.arity == 1
					yield(builder)
				else
					builder.instance_eval(&block)
				end
				
				return builder
			end
			
			def initialize(import_map, base: nil)
				@import_map = import_map
				@base = Protocol::URL[base]
			end
			
			# Add an import mapping with the current base URI.
			#
			# If a base is set, the value is resolved relative to that base following RFC 3986.
			# Absolute URLs (scheme://...) are preserved as-is when used as values.
			#
			# @parameter specifier [String] The module specifier (e.g., "react", "@myapp/utils").
			# @parameter value [String] The URL or path to resolve to.
			# @parameter integrity [String, nil] Optional subresource integrity hash.
			# @returns [Builder] Self for method chaining.
			#
			# @example With base URL.
			# 	builder = Builder.new(map, base: "https://cdn.com/")
			# 	builder.import("lib", "lib.js")  # Resolves to: "https://cdn.com/lib.js"
			# 	builder.import("ext", "https://other.com/ext.js")  # Keeps: "https://other.com/ext.js"
			def import(specifier, value, integrity: nil)
				resolved_value = if @base
					value_url = Protocol::URL[value]
					
					# Combine base with value
					(@base + value_url).to_s
				else
					value
				end
				
				@import_map.import(specifier, resolved_value, integrity: integrity)
				
				self
			end
			
			# Create a nested scope with a different base URI.
			#
			# The new base is resolved relative to the current base. This allows for
			# hierarchical organization of imports from different sources.
			#
			# @parameter base [String] The new base URI, resolved relative to current base.
			# @yields [Builder] A new builder with the resolved base.
			# @returns [Builder] The builder instance.
			#
			# @example Nested CDN paths.
			# 	builder.with(base: "https://cdn.com/") do |cdn|
			# 		cdn.with(base: "libs/v2/") do |v2|
			# 			# Base is now: "https://cdn.com/libs/v2/"
			# 			v2.import("util", "util.js")  # => "https://cdn.com/libs/v2/util.js"
			# 		end
			# 	end
			def with(base:, &block)
				# Resolve the new base relative to the current base
				resolved_base = if @base
					@base + Protocol::URL[base]
				else
					base
				end
				
				self.class.build(@import_map, base: resolved_base, &block)
			end
			
			# Add a scope mapping.
			#
			# Scopes allow different import resolutions for different parts of your application.
			#
			# @parameter scope_prefix [String] The scope prefix (e.g., "/pages/").
			# @parameter imports [Hash] Import mappings specific to this scope.
			# @returns [Builder] Self for method chaining.
			#
			# @example Scope-specific imports.
			# 	builder.scope("/admin/", {"utils" => "/admin/utils.js"})
			def scope(scope_prefix, imports)
				@import_map.scope(scope_prefix, imports)
				self
			end
		end
		
		# Create an import map using a builder pattern.
		#
		# The builder supports both block parameter and instance_eval styles.
		# The returned import map is frozen to prevent accidental mutation.
		#
		# @parameter base [String, nil] The base URI for resolving relative paths.
		# @yields {|builder| ...} If a block is given.
		# 	@parameter builder [Builder] The import map builder, if the block takes an argument.
		# @returns [ImportMap] A frozen import map instance.
		#
		# @example Block parameter style.
		# 	import_map = ImportMap.build do |map|
		# 		map.import("react", "https://esm.sh/react")
		# 	end
		#
		# @example Instance eval style.
		# 	import_map = ImportMap.build do
		# 		import "react", "https://esm.sh/react"
		# 	end
		def self.build(base: nil, &block)
			instance = self.new(base: base)
			
			builder = Builder.build(instance, &block)
			
			return instance.freeze
		end
		
		# Initialize a new import map.
		#
		# Typically you should use {build} instead of calling this directly.
		#
		# @parameter imports [Hash] The imports mapping.
		# @parameter integrity [Hash] Integrity hashes for imports.
		# @parameter scopes [Hash] Scoped import mappings.
		# @parameter base [String, Protocol::URL, nil] The base URI for resolving relative paths.
		def initialize(imports = {}, integrity = {}, scopes = {}, base: nil)
			@imports = imports
			@integrity = integrity
			@scopes = scopes
			@base = Protocol::URL[base]
		end
		
		# @attribute [Hash(String, String)] The imports mapping.
		attr :imports
		
		# @attribute [Hash(String, String)] Subresource integrity hashes for imports.
		attr :integrity
		
		# @attribute [Hash(String, Hash)] Scoped import mappings.
		attr :scopes
		
		# @attribute [Protocol::URL::Absolute | Protocol::URL::Relative | nil] The parsed base URL for efficient resolution.
		attr :base
		
		# Add an import mapping.
		#
		# @parameter specifier [String] The import specifier (e.g., "react", "@myapp/utils").
		# @parameter value [String] The URL or path to resolve to.
		# @parameter integrity [String, nil] Optional subresource integrity hash for the resource.
		# @returns [ImportMap] Self for method chaining.
		def import(specifier, value, integrity: nil)
			@imports[specifier] = value
			@integrity[specifier] = integrity if integrity
			
			self
		end
		
		# Add a scope mapping.
		#
		# Scopes allow different import resolutions based on the referrer URL.
		# See https://github.com/WICG/import-maps#scoping-examples for details.
		#
		# @parameter scope_prefix [String] The scope prefix (e.g., "/pages/").
		# @parameter imports [Hash] Import mappings specific to this scope.
		# @returns [ImportMap] Self for method chaining.
		def scope(scope_prefix, imports)
			@scopes[scope_prefix] = imports
			
			self
		end
		
		# Create a new import map with paths relative to the given page path.
		# This is useful for creating page-specific import maps from a global one.
		#
		# @parameter path [String] The absolute page path to make imports relative to.
		# @returns [ImportMap] A new import map with a relative base.
		#
		# @example Creating page-specific import maps.
		# 	# Global import map with base: "/_components/"
		# 	import_map = ImportMap.build(base: "/_components/") { ... }
		# 	
		# 	# For a page at /foo/bar/, calculate relative path to components
		# 	page_map = import_map.relative_to("/foo/bar/")
		# 	# Base becomes: "../../_components/"
		def relative_to(path)
			if @base
				# Calculate the relative path from the page to the base
				relative_base = Protocol::URL::Path.relative(@base.path, path)
				resolved_base = Protocol::URL[relative_base]
			else
				resolved_base = nil
			end
			
			instance = self.class.new(@imports.dup, @integrity.dup, @scopes.dup, base: resolved_base)
			
			return instance.freeze
		end
		
		# Resolve a single import value considering base context.
		#
		# @parameter value [String] The import URL or path value.
		# @parameter base [Protocol::URL, nil] The base URL context for resolving relative paths.
		# @returns [Protocol::URL, String] The resolved URL object or original string.
		private def resolve_value(value, base)
			if base
				base + Protocol::URL[value]
			else
				value
			end
		end
		
		# Resolve a hash of imports with the given base.
		#
		# @parameter imports [Hash] The imports hash to resolve.
		# @parameter base [Protocol::URL, nil] The base URL context.
		# @returns [Hash] The resolved imports with string values.
		private def resolve_imports(imports, base)
			result = {}
			
			imports.each do |specifier, value|
				result[specifier] = resolve_value(value, base).to_s
			end
			
			result
		end
		
		# Build the import map as a Hash with resolved paths.
		#
		# All relative paths are resolved against the base URL if present.
		# Absolute URLs and protocol-relative URLs are preserved as-is.
		# This method is compatible with the JSON gem's `as_json` convention.
		#
		# @returns [Hash] The resolved import map data structure ready for JSON serialization.
		def as_json(...)
			result = {}
			
			# Add imports
			if @imports.any?
				result["imports"] = resolve_imports(@imports, @base)
			end
			
			# Add scopes
			if @scopes.any?
				result["scopes"] = {}
				@scopes.each do |scope_prefix, scope_imports|
					# Resolve the scope prefix itself with base
					scope_url = Protocol::URL[scope_prefix]
					resolved_prefix = if @base && !scope_url.is_a?(Protocol::URL::Absolute)
						(@base + scope_url).to_s
					else
						scope_prefix
					end
					
					result["scopes"][resolved_prefix] = resolve_imports(scope_imports, @base)
				end
			end
			
			# Add integrity
			if @integrity.any?
				result["integrity"] = @integrity.dup
			end
			
			return result
		end
		
		# Convert the import map to JSON.
		#
		# @returns [String] The JSON representation of the import map.
		def to_json(...)
			as_json.to_json(...)
		end
		
		# Generate the import map as an XRB fragment suitable for embedding in HTML.
		#
		# Creates a `<script type="importmap">` tag containing the JSON representation.
		#
		# @returns [XRB::Builder::Fragment] The generated HTML fragment.
		def to_html
			json_data = to_json
			
			XRB::Builder.fragment do |builder|
				builder.inline("script", type: "importmap") do
					builder.text(json_data)
				end
			end
		end
		
		# Convenience method for rendering the import map as an HTML string.
		#
		# Equivalent to `to_html.to_s`.
		#
		# @returns [String] The generated HTML containing the import map script tag.
		def to_s
			to_html.to_s
		end
	end
end
