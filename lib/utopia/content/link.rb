# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2009-2025, by Samuel Williams.
# Copyright, 2017, by Huba Nagy.
# Copyright, 2020, by Michael Adams.

require "yaml"
require "xrb/builder"

require "xrb/strings"

require_relative "../path"

module Utopia
	module Content
		# Represents a link to some content with associated metadata.
		class Link
			# @param kind [Symbol] the kind of link.
			def initialize(kind, name, locale, path, info, title = nil)
				@kind = kind
				@name = name
				@locale = locale
				@path = Path.create(path)
				@info = info || {}
				@title = XRB::Strings.to_title(title || name)
			end
			
			# Build the filesystem key, including the locale suffix when present.
			# @returns [String | nil] The link key.
			def key
				if @path
					if locale
						"#{@path.last}.#{@locale}"
					else
						@path.last
					end
				end
			end
			
			# Resolve the backing content file beneath a root directory.
			# @parameter root [String] The root directory.
			# @parameter extension [String] The file extension.
			# @returns [String | nil] The backing file path, or `nil` for links without file paths.
			def full_path(root, extension = XNODE_EXTENSION)
				if @path&.file?
					File.join(root, @path.dirname, self.key + XNODE_EXTENSION)
				end
			end
			
			# Resolve this link's target URI.
			# @returns [String | nil] The explicit target URI or one derived from the content path.
			def href
				@href ||= @info.fetch(:uri) do
					@info.fetch(:href) do
						(@path.dirname + @path.basename).to_s if @path
					end
				end
			end
			
			# Look up from the `links.yaml` metadata with a given symbolic key.
			def [] key
				@info[key]
			end
			
			attr :kind
			attr :name
			attr :path
			attr :info
			attr :locale
			
			# Check whether this link has a target URI.
			# @returns [Boolean] Whether this link has a target URI.
			def href?
				!!href
			end
			
			# Check whether this link refers to an index document.
			# @returns [Boolean] Whether this link represents an index document.
			def index?
				@kind == :index
			end
			
			# Check whether this link is virtual.
			# @returns [Boolean] Whether this link exists only in metadata.
			def virtual?
				@kind == :virtual
			end
			
			# Resolve this link's target relative to a base path.
			# @parameter base [Path | String | nil] The source path.
			# @returns [Path | String | nil] The relative or unchanged target.
			def relative_href(base = nil)
				if base and href.start_with? "/"
					Path.shortest_path(href, base)
				else
					href
				end
			end
			
			# Return the display title from metadata or the inferred title.
			# @returns [String] The display title.
			def title
				@info.fetch(:title, @title)
			end
			
			# Render this link as an anchor element.
			# @parameter base [Path | String | nil] The source path for relative links.
			# @parameter content [String] The content.
			# @parameter builder [XRB::Builder] The markup builder.
			# @parameter attributes [Hash] The attributes.
			# @returns [XRB::Builder::Fragment] The rendered anchor or span fragment.
			def to_anchor(base: nil, content: self.title, builder: nil, **attributes)
				attributes[:class] ||= "link"
				
				XRB::Builder.fragment(builder) do |inner_builder|
					if href?
						attributes[:href] ||= relative_href(base)
						attributes[:target] ||= @info[:target]
						
						inner_builder.inline("a", attributes) do
							inner_builder.text(content)
						end
					else
						inner_builder.inline("span", attributes) do
							inner_builder.text(content)
						end
					end
				end
			end
			
			alias to_href to_anchor
			
			# Convert this object to a string.
			# @returns [String] The resulting string.
			def to_s
				"\#<#{self.class}(#{self.kind}) title=#{title.inspect} href=#{href.inspect}>"
			end
			
			# Check whether this object is equivalent to another object.
			# @parameter other [Object] The object to compare.
			# @returns [Boolean] Whether both links have equivalent metadata.
			def eql? other
				self.class.eql?(other.class) and kind.eql?(other.kind) and name.eql?(other.name) and path.eql?(other.path) and info.eql?(other.info)
			end
			
			# Compare this object with another object.
			# @parameter other [Object] The object to compare.
			# @returns [Boolean | nil] Whether both links have the same kind, name, and path.
			def == other
				other and kind == other.kind and name == other.name and path == other.path
			end
			
			# Check whether this link uses the default locale.
			# @returns [Boolean] Whether this link has no locale override.
			def default_locale?
				@locale == nil
			end
		end
	end
end
