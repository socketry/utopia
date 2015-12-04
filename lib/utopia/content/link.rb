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
require_relative '../locale'

module Utopia
	class Content
		class Link
			def initialize(kind, path, info = nil)
				path = Path.create(path)

				@info = info || {}
				@kind = kind

				case @kind
				when :file
					@name, @locale = path.last.split('.', 2)
					@path = path
				when :directory
					# raise ArgumentError unless path.last.start_with? INDEX
					
					@name = path.dirname.last
					@locale = path.last.split('.', 2)[1]
					@path = path
				when :virtual
					@name, @locale = path.to_s.split('.', 2)
					@path = @info[:path] ? Path.create(@info[:path]) : nil
				else
					raise ArgumentError.new("Unknown link kind #{@kind} with path #{path}")
				end
				
				@title = Trenni::Strings.to_title(@name)
			end

			def href
				@href ||= @info.fetch(:uri) do
					(@path.dirname + @path.basename.parts[0]).to_s if @path
				end
			end

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

			def to_href(**options)
				Trenni::Builder.fragment(options[:builder]) do |builder|
					if href?
						relative_href(options[:base])
						
						builder.inline('a', class: options.fetch(:class, 'link'), href: relative_href(options[:base])) do
							builder.text(options[:content] || title)
						end
					else
						builder.inline('span', class: options.fetch(:class, 'link')) do
							builder.text(options[:content] || title)
						end
					end
				end
			end
			
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
