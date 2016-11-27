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

require 'trenni/markup'

module Utopia
	class Content
		# This represents an individual SGML tag, e.g. <a>, </a> or <a />, with attributes. Attribute values must be escaped.
		Tag = Struct.new(:name, :closed, :attributes) do
			include Trenni::Markup
			
			def self.closed(name, **attributes)
				self.new(name, true, attributes)
			end
			
			def self.opened(name, **attributes)
				self.new(name, false, attributes)
			end
			
			def [] key
				attributes[key]
			end
			
			alias to_hash attributes
			
			def to_s(content = nil)
				buffer = String.new.force_encoding(name.encoding)
				
				write(buffer, content)
				
				return buffer
			end
			
			alias to_str to_s
			
			def self_closed?
				closed
			end
			
			def write_opening_tag(buffer, self_closing = false)
				buffer << "<#{name}"

				attributes.each do |key, value|
					if value
						buffer << " #{key}=\"#{value}\""
					else
						buffer << " #{key}"
					end
				end
				
				if self_closing
					buffer << "/>"
				else
					buffer << ">"
				end
			end
			
			def write_closing_tag(buffer)
				buffer << "</#{name}>"
			end
			
			def write(buffer, content = nil)
				if closed and content.nil?
					write_opening_tag(buffer, true)
				else
					write_opening_tag(buffer)
					buffer << content if content
					write_closing_tag(buffer)
				end
			end
		end
	end
end
