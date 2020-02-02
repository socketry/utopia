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
		XNODE_EXTENSION = '.xnode'.freeze
		
		class Links
			def self.for(root, path, locale = nil)
				warn "Using uncached links metadata!"
				self.new(root).for(path, locale)
			end
			
			def self.index(root, path, **options)
				warn "Using uncached links metadata!"
				self.new(root).index(path, **options)
			end
			
			XNODE_FILTER = /^(.+)#{Regexp.escape XNODE_EXTENSION}$/
			INDEX_XNODE_FILTER = /^(index(\..+)*)#{Regexp.escape XNODE_EXTENSION}$/
			
			def initialize(root)
				@root = root
				
				@cache = Concurrent::Map.new
			end
			
			def for(path, locale = nil)
				links = Resolved.new(self, path.dirname)
				
				links.lookup(path.last, locale)
			end
			
			DEFAULT_INDEX_OPTIONS = {
				:directories => true,
				:files => true,
				:virtuals => true,
				:indices => false,
				:sort => :order,
				:display => :display,
			}
			
			def index(path, **options)
				options = DEFAULT_INDEX_OPTIONS.merge(options)
				
				ordered = Resolved.new(self, path, options).ordered
				
				# This option filters a link based on the display parameter.
				if display_key = options[:display]
					ordered.reject!{|link| link.info[display_key] == false}
				end
				
				# Named:
				if name = options[:name]
					# We use pattern === name, which matches either the whole string, or matches a regexp.
					ordered.select!{|link| name === link.name}
				end
				
				if locale = options[:locale]
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
				
				# Sort:
				if sort_key = options[:sort]
					# Sort by sort_key, otherwise by title.
					ordered.sort_by!{|link| [link[sort_key] || options[:sort_default] || 0, link.title]}
				end
				
				return ordered
			end
			
			attr :root
			
			# Represents a list of {Link} instances relating to the structure of the content. They are formed from the `links.yaml` file and the actual directory structure on disk.
			class Resolved
				DEFAULT_OPTIONS = {
					:directories => true,
					:files => true,
					:virtuals => true,
					:indices => true,
				}
				
				def initialize(links, top = Path.root, options = DEFAULT_OPTIONS)
					raise ArgumentError.new("top path must be absolute") unless top.absolute?
					
					@links = links
					
					@top = top
					@options = options
					
					# top.components.first == '', but this isn't a problem here.
					@path = File.join(links.root, top.components)
					
					@ordered = []
					@named = Hash.new{|h,k| h[k] = []}
					
					if File.directory? @path
						@metadata = links.metadata(@path)
						
						load_links(@metadata.dup) do |link|
							@ordered << link
							@named[link.name] << link
						end
					else
						@metadata = {}
					end
				end
				
				attr :top
				attr :ordered
				attr :named
				
				def each(locale)
					return to_enum(:each, locale) unless block_given?
					
					ordered.each do |links|
						yield links.find{|link| link.locale == locale}
					end
				end
				
				def lookup(name, locale = nil)
					# This allows generic links to serve any locale requested.
					if links = @named[name]
						links.find{|link| link.locale == locale} || links.find{|link| link.locale == nil}
					end
				end
				
				private
				
				def indices(path, &block)
					Dir.entries(path).select{|filename| filename.match(INDEX_XNODE_FILTER)}
				end
				
				def load_indices(name, path, metadata)
					directory_metadata = metadata.delete(name) || {}
					indices_metadata = @links.metadata(path)
					
					indices_count = 0
					
					indices(path).each do |filename|
						index_name = File.basename(filename, XNODE_EXTENSION)
						# Values in indices_metadata will override values in directory_metadata:
						index_metadata = directory_metadata.merge(indices_metadata[index_name] || {})
						
						directory_link = Link.new(:directory, @top + [name, index_name], index_metadata)
						
						# Merge metadata from foo.en into foo/index.en
						if directory_link.locale
							localized_key = "#{directory_link.name}.#{directory_link.locale}"
							if localized_metadata = metadata.delete(localized_key)
								directory_link.info.update(localized_metadata)
							end
						end
						
						yield directory_link
						
						indices_count += 1
					end
					
					if indices_count == 0
						# Specify a nil uri if no index could be found for the directory:
						yield Link.new(:directory, top + [name], {:uri => nil}.merge(directory_metadata))
					end
				end
				
				def entries(path)
					Dir.entries(path).reject{|filename| filename.match(/^[\._]/)}
				end
				
				def load_links(metadata, &block)
					# Load all metadata for a given path:
					metadata = @metadata.dup
					
					# Check all entries in the given directory:
					entries(@path).each do |filename|
						path = File.join(@path, filename)
						
						# There are two types of filelinks based links:
						# 1/ Named files, e.g. foo.xnode, name=foo
						# 2/ Directories, e.g. bar/index.xnode, name=bar
						if File.directory?(path) and @options[:directories]
							load_indices(filename, path, metadata, &block)
						elsif filename.match(INDEX_XNODE_FILTER) and @options[:indices] == false
							metadata.delete($1) # We don't include indices in the list of pages.
						elsif filename.match(XNODE_FILTER) and @options[:files]
							yield Link.new(:file, @top + $1, metadata.delete($1))
						end
					end
					
					if @options[:virtuals]
						# After processing all directory entries, we are left with virtual entries in the metadata:
						metadata.each do |name, info|
							virtual_link = Link.new(:virtual, name, info)
							
							# Given a virtual named such as "welcome.cn", merge it with metadata from "welcome" if it exists:
							if virtual_metadata = @metadata[virtual_link.name]
								virtual_link.info.update(virtual_metadata)
							end
							
							yield virtual_link
						end
					end
				end
			end
			
			def metadata(path)
				@cache.fetch_or_store(path.to_s) do
					load(path).freeze
				end
			end
			
			private
			
			def symbolize_keys(hash)
				# Second level attributes should be symbolic:
				hash.each do |key, info|
					hash[key] = info.each_with_object({}) { |(k,v),result| result[k.to_sym] = v }
				end
				
				return hash
			end
			
			LINKS_YAML = "links.yaml"
			
			def load(path)
				yaml_path = File.join(path, LINKS_YAML)
				
				if File.exist?(yaml_path) && data = YAML::load_file(yaml_path)
					return symbolize_keys(data)
				else
					return {}
				end
			end
		end
	end
end
