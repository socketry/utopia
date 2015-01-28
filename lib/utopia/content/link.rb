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

require 'yaml'
require 'trenni/builder'

require_relative '../content'
require_relative '../path'

module Utopia
	class Content
		XNODE_EXTENSION = '.xnode'.freeze
		
		class Link
			def initialize(kind, path, info = nil)
				path = Path.create(path)

				@info = info || {}
				@kind = kind

				case @kind
				when :file
					name = path.last
					@path = path
				when :directory
					name = path.dirname.last
					@path = path
				when :virtual
					name = path.to_s
					@path = @info[:path] ? Path.create(@info[:path]) : nil
				else
					raise ArgumentError.new("Unknown link kind #{@kind} with path #{path}")
				end
				
				basename = Basename.new(name)
				
				@name = basename.parts[0]
				
				@href = @info.fetch(:uri) do
					(@path.dirname + @path.basename.parts[0]).to_s if @path
				end
				
				@title = Trenni::Strings.to_title(basename.name)
				@variant = basename.variant
			end

			def method_missing(name)
				@info[name]
			end

			def respond_to? name
				@info.key?(name) || super
			end

			def [] key
				@info[key]
			end

			attr :kind
			attr :name
			attr :path
			attr :href # the path without any variant
			attr :info
			attr :variant

			def href?
				return href != nil
			end

			def title
				@info.fetch(:title, @title)
			end

			def to_href(options = {})
				Trenni::Builder.fragment(options[:builder]) do |builder|
					if href?
						builder.inline('a', class: options.fetch(:class, 'link'), href: href) do
							builder.text(options[:content] || title)
						end
					else
						builder.inline('span', class: options.fetch(:class, 'link')) do
							builder.text(options[:content] || title)
						end
					end
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
			
			def default_locale?
				@locale == nil
			end
		end
		
		# Links are essentially a static list of information relating to the structure of the content. They are formed from the `links.yaml` file and the actual files on disk. 
		class Links
			def self.for(root, path, variant = nil)
				links = self.new(root, path.dirname)
				
				links.lookup(path.last, variant)
			end
			
			DEFAULT_INDEX_OPTIONS = {
				:directories => true,
				:files => true,
				:virtuals => true,
				:indices => false,
				:sort => :order,
				:display => :display,
			}
			
			def self.index(root, path, options = {})
				options = DEFAULT_INDEX_OPTIONS.merge(options)
				
				ordered = self.new(root, path, options).ordered
				
				# This option filters a link based on the display parameter.
				if display_key = options[:display]
					ordered.reject!{|link| link.info[display_key] == false}
				end
				
				# Named:
				if name = options[:name]
					ordered.select!{|link| link.name[options[:name]]}
				end
				
				# Sort:
				if sort_key = options[:sort]
					# Sort by sort_key, otherwise by title.
					ordered.sort_by!{|link| [link.send(sort_key) || options[:sort_default] || 0, link.title]}
				end
				
				if variant = options[:variant]
					variants = {}
					
					ordered.each do |link|
						if link.variant == variant
							variants[link.name] = link
						else
							variants[link.name] ||= link
						end
					end
					
					ordered = variants.values
				end
				
				return ordered
			end
			
			XNODE_FILTER = /^(.+)#{Regexp.escape XNODE_EXTENSION}$/
			INDEX_XNODE_FILTER = /^(index(\..+)*)#{Regexp.escape XNODE_EXTENSION}$/
			LINKS_YAML = "links.yaml"
			
			DEFAULT_OPTIONS = {
				:directories => true,
				:files => true,
				:virtuals => true,
				:indices => true,
			}
			
			def initialize(root, top = Path.new, options = DEFAULT_OPTIONS)
				@top = top
				@options = options
				
				@path = File.join(root, top.components)
				@metadata = self.class.metadata(@path)
				
				@ordered = []
				@named = Hash.new{|h,k| h[k] = []}
				
				if File.directory? @path
					load_links(@metadata.dup) do |link|
						@ordered << link
						@named[link.name] << link
					end
				end
			end
			
			attr :top
			attr :ordered
			attr :named
			
			def each(variant)
				return to_enum(:each, variant) unless block_given?
				
				ordered.each do |links|
					yield links.find{|link| link.variant == variant}
				end
			end
			
			def lookup(name, variant = nil)
				# This allows generic links to serve any variant requested.
				if links = @named[name]
					links.find{|link| link.variant == variant} || links.find{|link| link.variant == nil}
				end
			end
			
			private
			
			def self.symbolize_keys(hash)
				# Second level attributes should be symbolic:
				hash.each do |key, info|
					hash[key] = info.each_with_object({}) { |(k,v),result| result[k.to_sym] = v }
				end
				
				return hash
			end
			
			def self.metadata(path)
				links_path = File.join(path, LINKS_YAML)
				
				hash = if File.exist?(links_path)
					YAML::load(File.read(links_path)) || {}
				else
					{}
				end
				
				return symbolize_keys(hash)
			end
			
			def indices(path, &block)
				Dir.entries(path).reject{|filename| !filename.match(INDEX_XNODE_FILTER)}
			end

			def load_indices(name, path, metadata)
				directory_metadata = metadata.delete(name) || {}
				indices_metadata = Links.metadata(path)
				
				indices_count = 0
				
				indices(path).each do |filename|
					index_name = File.basename(filename, XNODE_EXTENSION)
					# Values in indices_metadata will override values in directory_metadata:
					index_metadata = directory_metadata.merge(indices_metadata[index_name] || {})
					
					directory_link = Link.new(:directory, @top + [name, index_name], index_metadata)
					
					yield directory_link
					
					indices_count += 1
				end
				
				if indices_count == 0
					# Specify a nil uri if no index could be found for the directory:
					yield Link.new(:directory, top + [name, ""], {:uri => nil}.merge(directory_metadata))
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
					
					# There are two types of filesystem based links:
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
						yield Link.new(:virtual, name, info)
					end
				end
			end
		end
	end
end
