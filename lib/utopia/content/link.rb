# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2009-2024, by Samuel Williams.
# Copyright, 2017, by Huba Nagy.
# Copyright, 2020, by Michael Adams.

require 'yaml'
require 'xrb/builder'

require 'xrb/strings'

require_relative '../path'
require_relative '../locale'

module Utopia
	class Content
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
			
			def key
				if @path
					if locale
						"#{@path.last}.#{@locale}"
					else
						@path.last
					end
				end
			end
			
			def full_path(root, extension = XNODE_EXTENSION)
				if @path&.file?
					File.join(root, @path.dirname, self.key + XNODE_EXTENSION)
				end
			end
			
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
			
			def href?
				!!href
			end
			
			def index?
				@kind == :index
			end
			
			def virtual?
				@kind == :virtual
			end
			
			def relative_href(base = nil)
				if base and href.start_with? '/'
					Path.shortest_path(href, base)
				else
					href
				end
			end
			
			def title
				@info.fetch(:title, @title)
			end
			
			def to_anchor(base: nil, content: self.title, builder: nil, **attributes)
				attributes[:class] ||= 'link'
				
				XRB::Builder.fragment(builder) do |inner_builder|
					if href?
						attributes[:href] ||= relative_href(base)
						attributes[:target] ||= @info[:target]
						
						inner_builder.inline('a', attributes) do
							inner_builder.text(content)
						end
					else
						inner_builder.inline('span', attributes) do
							inner_builder.text(content)
						end
					end
				end
			end
			
			alias to_href to_anchor
			
			def to_s
				"\#<#{self.class}(#{self.kind}) title=#{title.inspect} href=#{href.inspect}>"
			end
			
			def eql? other
				self.class.eql?(other.class) and kind.eql?(other.kind) and name.eql?(other.name) and path.eql?(other.path) and info.eql?(other.info)
			end
			
			def == other
				other and kind == other.kind and name == other.name and path == other.path
			end
			
			def default_locale?
				@locale == nil
			end
		end
	end
end
