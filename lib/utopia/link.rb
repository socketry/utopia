#	This file is part of the "Utopia Framework" project, and is licensed under the GNU AGPLv3.
#	Copyright 2010 Samuel Williams. All rights reserved.
#	See <utopia.rb> for licensing details.

require 'utopia/extensions'

module Utopia

	class Link
		XNODE_EXT = ".xnode"

		def initialize(kind, path, info = nil)
			path = Path.create(path)

			@kind = kind

			case @kind
			when :file
				@name = path.basename(XNODE_EXT)
				@path = path
			when :directory
				@name = path.dirname.basename(XNODE_EXT)
				@path = path
			when :virtual
				@name = path.to_s
				@path = nil
			end

			@components = @name.split(".")
			@locale = path.locale(XNODE_EXT)

			@title = components[0]

			if info
				@info = info.symbolize_keys
			else
				@info = {}
			end
		end

		attr :kind
		attr :name
		attr :path
		attr :locale
		attr :info
		attr :components

		def [] (key)
			if key == :title
				return @title
			end
			
			return @info[key]
		end

		def href
			if @info[:uri]
				return @info[:uri]
			elsif @path
				return @path.to_s
			else
				"\#"
			end
		end

		def href?
			return href != "\#"
		end

		def title
			@info[:title] || @title.to_title
		end

		def external?
			@info.key? :uri
		end

		def to_href(options = {})
			options[:content] ||= title
			options[:class] ||= "link"
			
			if href == "\#"
				"<span class=#{options[:class].dump}>#{options[:content].to_html}</span>"
			else
				"<a class=#{options[:class].dump} href=\"#{href.to_html}\">#{options[:content].to_html}</a>"
			end
		end
		
		def eql? other
			if other && self.class == other.class
				return kind.eql?(other.kind) && 
				       name.eql?(other.name) && 
				       path.eql?(other.path) && 
				       info.eql?(other.info)
			else
				return false
			end
		end

		def == other
			return other && kind == other.kind && name == other.name && path == other.path
		end
	end
	
	module Links
		XNODE_FILTER = /^(.+)\.xnode$/
		INDEX_XNODE_FILTER = /^(index(\..+)*)\.xnode$/
		LINKS_YAML = "links.yaml"

		def self.metadata(path)
			links_path = File.join(path, LINKS_YAML)
			if File.exist?(links_path)
				return YAML::load(File.read(links_path))
			else
				return {}
			end
		end

		def self.indices(path, &block)
			entries = Dir.entries(path).delete_if{|filename| !filename.match(INDEX_XNODE_FILTER)}

			if block_given?
				entries.each &block
			else
				return entries
			end
		end

		DEFAULT_OPTIONS = {
			:directories => true,
			:files => true,
			:virtual => true,
			:indices => false,
			:sort => :order,
			:hidden => :hidden,
			:locale => nil
		}
		
		def self.index(root, top, options = {})
			options = DEFAULT_OPTIONS.merge(options)
			path = File.join(root, top.components)
			metadata = Links.metadata(path)

			links = []

			Dir.entries(path).each do |filename|
				next if filename.match(/^[\._]/)

				fullpath = File.join(path, filename)

				if File.directory?(fullpath) && options[:directories]
					name = filename
					indices_metadata = Links.metadata(fullpath)

					directory_metadata = metadata.delete(name) || {}
					indices = 0
					Links.indices(fullpath) do |index|
						index_name = File.basename(index, ".xnode")
						index_metadata = directory_metadata.merge(indices_metadata[index_name] || {})

						directory_link = Link.new(:directory, top + [filename, index_name], index_metadata)

						# Check for localized directory metadata and update the link
						if directory_link.locale
							localized_metadata = metadata.delete(name + "." + directory_link.locale)

							if localized_metadata
								directory_link.info.update(localized_metadata.symbolize_keys)
							end
						end

						links << directory_link

						indices += 1
					end

					if indices == 0
						links << Link.new(:directory, top + [filename, ""], directory_metadata.merge(:uri => "\#"))
					end
				elsif filename.match(INDEX_XNODE_FILTER) && options[:indices] == false
					name = $1
					metadata.delete(name)

					# We don't include indices in the list of pages.
					next
				elsif filename.match(XNODE_FILTER) && options[:files]
					name = $1

					links << Link.new(:file, top + name, metadata.delete(name))
				end
			end

			if options[:virtual]
				metadata.each do |name, details|
					links << Link.new(:virtual, name, details)
				end
			end

			if options[:hidden]
				links = links.delete_if{|link| link[options[:hidden]]}
			end

			if options[:name]
				case options[:name]
				when Regexp
					links.reject!{|link| !link.name.match(options[:name])}
				when String
					links.reject!{|link| link.name.index(options[:name]) != 0}
				end
			end

			if options[:locale]
				reduced = []

				links.group_by(&:name).each do |name, links|
					default = nil

					link = links.select{|link|
						link.locale == options[:locale] || link.locale == ''
					}.sort_by{|link| link.locale.size}.last

					if link
						reduced << link
					end
				end
				
				links = reduced
			end
			
			if options[:sort]
				sort_key = options[:sort]
				sort_default = options[:sort_default] || 0
				
				links = links.sort do |a, b|
					result = nil

					lhs = a[sort_key] || sort_default
					rhs = b[sort_key] || sort_default
					
					begin
						result ||= lhs <=> rhs
					rescue
						# LOG.debug("Invalid comparison between #{a.path} and #{b.path} using key #{options[:sort]}!")
					end
					
					if result == 0 || result == nil
						a.title <=> b.title
					else
						result
					end
				end
			end
			
			return links
		end
	end
	
end
