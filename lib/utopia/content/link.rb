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

require 'yaml'
require 'trenni/builder'

require 'trenni/strings'

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
				@title = Trenni::Strings.to_title(title || name)
			end
			
			def href
				@href ||= @info.fetch(:uri) do
					(@path.dirname + @path.basename).to_s if @path
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
				
				Trenni::Builder.fragment(builder) do |builder|
					if href?
						attributes[:href] ||= relative_href(base)
						attributes[:target] ||= @info[:target]
						
						builder.inline('a', attributes) do
							builder.text(content)
						end
					else
						builder.inline('span', attributes) do
							builder.text(content)
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
