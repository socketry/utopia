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

module Utopia
	module Middleware
		class Content
			class Tag
				def == other
					if Tag === other
						[@name, @attributes, @closed] == [other.name, other.attributes, other.closed]
					end
				end
				
				def self.closed(name, attributes = {})
					tag = Tag.new(name, attributes)
					tag.closed = true
					
					return tag
				end
				
				def initialize(name, attributes = {})
					@name = name
					@attributes = attributes
					@closed = false
				end

				attr :name
				attr :attributes
				attr :closed, true

				def [](key)
					@attributes[key]
				end

				def append(text)
					@content ||= StringIO.new
					@content.write text
				end

				def to_html(content = nil, buffer = StringIO.new)
					write_full_html(buffer, content)
					
					return buffer.string
				end
				
				def to_hash
					@attributes
				end
				
				def to_s
					buffer = StringIO.new
					write_full_html(buffer)
					return buffer.string
				end
				
				def write_open_html(buffer, terminate = false)
					buffer ||= StringIO.new 
					buffer.write "<#{name}"

					@attributes.each do |key, value|
						if value
							buffer.write " #{key}=\"#{value}\""
						else
							buffer.write " #{key}"
						end
					end
					
					if terminate
						buffer.write "/>"
					else
						buffer.write ">"
					end
				end
				
				def write_close_html(buffer)
					buffer.write "</#{name}>"
				end
				
				def write_full_html(buffer, content = nil)
					if @closed && content == nil
						write_open_html(buffer, true)
					else
						write_open_html(buffer)
						buffer.write(content)
						write_close_html(buffer)
					end
				end
			end
		end
	end
end
