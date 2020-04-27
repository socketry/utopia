# frozen_string_literal: true

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

require_relative 'link'

require 'concurrent/map'

module Utopia
	class Content
		# The file extension for markup nodes on disk.
		XNODE_EXTENSION = '.xnode'
		INDEX = "index"
		
		class Links
			def self.for(root, path, locale = nil)
				warn "Using uncached links metadata!"
				self.new(root).for(path, locale)
			end
			
			def self.index(root, path, **options)
				warn "Using uncached links metadata!"
				self.new(root).index(path, **options)
			end
			
			def initialize(root, extension: XNODE_EXTENSION)
				@root = root
				
				@extension = extension
				@file_filter = /\A(?<key>(?<name>[^.]+)(\.(?<locale>.+))?)#{Regexp.escape extension}\Z/
				@index_filter = /\A(?<key>(?<name>index)(\.(?<locale>.+))?)#{Regexp.escape extension}\Z/
				
				@metadata_cache = Concurrent::Map.new
				@links_cache = Concurrent::Map.new
			end
			
			attr :extension
			attr :file_filter
			attr :index_filter
			
			# Resolve a link for the specified path, which must be a path to a specific link.
			# 	for(Path["/index"])
			def for(path, locale = nil)
				links(path.dirname).lookup(path.last, locale)
			end
			
			# Give an index of all links that can be reached from the given path.
			def index(path, name: nil, locale: nil, display: :display, sort: :order, sort_default: 0, directories: true, files: true, virtuals: true, indices: false)
				ordered = links(path).ordered.dup
				
				# Ignore specific kinds of links:
				ignore = []
				ignore << :directory unless directories
				ignore << :file unless files
				ignore << :virtual unless virtuals
				ignore << :index unless indices
				
				if ignore.any?
					ordered.reject!{|link| ignore.include?(link.kind)}
				end
				
				# Filter links by display key:
				if display
					ordered.reject!{|link| link.info[display] == false}
				end
				
				# Filter links by name:
				if name
					# We use pattern === name, which matches either the whole string, or matches a regexp.
					ordered.select!{|link| name === link.name}
				end
				
				# Filter by locale:
				if locale
					locales = {}
					
					ordered.each do |link|
						if link.locale == locale
							locales[link.name] = link
						elsif link.locale == nil
							locales[link.name] ||= link
						end
					end
					
					ordered = locales.values
				end
				
				# Order by sort key:
				if sort
					# Sort by sort_key, otherwise by title.
					ordered.sort_by!{|link| [link[sort] || sort_default, link.title]}
				end
				
				return ordered
			end
			
			attr :root
			
			def metadata(path)
				@metadata_cache.fetch_or_store(path.to_s) do
					load_metadata(path)
				end
			end
			
			def links(path)
				@links_cache.fetch_or_store(path.to_s) do
					load_links(path)
				end
			end
			
			private
			
			def symbolize_keys(map)
				# Second level attributes should be symbolic:
				map.each do |key, info|
					map[key] = info.each_with_object({}) { |(k,v),result| result[k.to_sym] = v }
				end
				
				return map
			end
			
			LINKS_YAML = "links.yaml"
			
			def load_metadata(path)
				yaml_path = File.join(path, LINKS_YAML)
				
				if File.exist?(yaml_path) && data = YAML::load_file(yaml_path)
					return symbolize_keys(data)
				else
					return {}
				end
			end
			
			# Represents a list of {Link} instances relating to the structure of the content. They are formed from the `links.yaml` file and the actual directory structure on disk.
			class Resolver
				def initialize(links, top = Path.root)
					raise ArgumentError.new("top path must be absolute") unless top.absolute?
					
					@links = links
					
					@top = top
					
					# top.components.first == '', but this isn't a problem here.
					@path = File.join(links.root, top.components)
					
					if File.directory?(@path)
						@metadata = links.metadata(@path)
						@ordered = nil
					else
						@metadata = nil
						@ordered = []
					end
					
					@named = nil
				end
				
				attr :top
				
				def ordered
					if @ordered.nil?
						@ordered = []
						@named = {}
						
						load_links(@metadata.dup) do |link|
							@ordered << link
							(@named[link.name] ||= []) << link
						end
					end
					
					return @ordered
				end
				
				def named
					self.ordered
					
					return @named
				end
				
				def indices
					self.ordered
					
					return @ordered.select{|link| link.index?}
				end
				
				def each(locale)
					return to_enum(:each, locale) unless block_given?
					
					ordered.each do |links|
						yield links.find{|link| link.locale == locale}
					end
				end
				
				def lookup(name, locale = nil)
					self.ordered
					
					# This allows generic links to serve any locale requested.
					if links = @named[name]
						generic_link = nil
						
						links.each do |link|
							if link.locale == locale
								return link
							elsif link.locale.nil?
								generic_link = link
							end
						end
						
						return generic_link
					end
				end
				
				private
				
				def entries(path)
					Dir.entries(path).reject{|entry| entry.match(/^[\._]/)}
				end
				
				# @param name [String] the name of the directory.
				def load_directory(name, metadata, &block)
					defaults = metadata.delete(name) || {}
					
					links = @links.links(@top + name).indices
					
					links.each do |link|
						info = metadata.delete("#{name}.#{link.locale}") || {}
						
						yield Link.new(:directory, name, link.locale, link.path, defaults.merge(info, link.info))
					end
				end
				
				def load_index(name, locale, info)
					info ||=  {}
					
					if locale and defaults = @metadata[name]
						info = defaults.merge(info)
					end
					
					path = @top + name
					
					yield Link.new(:index, name, locale, path, info, path[-2])
				end
				
				def load_default_index(name = INDEX)
					path = @top + name
					
					# Specify a nil uri if no index could be found for the directory:
					yield Link.new(:index, name, nil, path, {:uri => nil}, path[-2])
				end
				
				def load_file(name, locale, info)
					info ||= {}
					
					if locale and defaults = @metadata[name]
						info = defaults.merge(info)
					end
					
					yield Link.new(:file, name, locale, @top + name, info)
				end
				
				def load_virtuals(metadata)
					virtuals = {}
					
					# After processing all directory entries, we are left with virtual links:
					metadata.each do |key, info|
						name, locale = key.split('.', 2)
						localized = (virtuals[name] ||= {})
						localized[locale] = info
					end
					
					virtuals.each do |name, localized|
						defaults = localized[nil]
						
						localized.each do |locale, info|
							info = defaults&.merge(info) || info
							path = info[:path]
							
							yield Link.new(:virtual, name, locale, path, info)
						end
					end
				end
				
				def load_links(metadata, &block)
					index_loaded = false
					
					# Check all entries in the given directory:
					entries(@path).each do |entry|
						path = File.join(@path, entry)
						
						# There are serveral types of file based links:
						
						# 1. Directories, e.g. bar/ (name=bar)
						if File.directory?(path)
							load_directory(entry, metadata, &block)
							
						# 2. Index files, e.g. index.xnode, name=parent
						elsif match = entry.match(@links.index_filter)
							load_index(match[:name], match[:locale], metadata.delete(match[:key]), &block)
							index_loaded = true
							
						# 3. Named files, e.g. foo.xnode, name=foo
						elsif match = entry.match(@links.file_filter)
							load_file(match[:name], match[:locale], metadata.delete(match[:key]), &block)
						end
					end
					
					unless index_loaded
						load_default_index(&block)
					end
					
					load_virtuals(metadata, &block)
				end
			end
			
			def load_links(path)
				Resolver.new(self, Path.create(path))
			end
		end
	end
end
