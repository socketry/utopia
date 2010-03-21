# Copyright (c) 2010 Samuel Williams. Released under the GNU GPLv3.
#
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
# 
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
# 
# You should have received a copy of the GNU General Public License
# along with this program.  If not, see <http://www.gnu.org/licenses/>.

module Utopia
	
	class Tag
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

		def to_html(content = nil, buf = StringIO.new)
			write_full_html(buf, content)
			
			return buf.string
		end
		
		def to_hash
			@attributes
		end
		
		def to_s
			buf = StringIO.new
			write_open_html(buf)
			return buf.string
		end
		
		def write_open_html(buf, terminate = false)
			buf ||= StringIO.new 
			buf.write "<#{name}"

			@attributes.each do |key, value|
				buf.write " #{key}=\"#{value}\""
			end
			
			if terminate
				buf.write "/>"
			else
				buf.write ">"
			end
		end
		
		def write_close_html(buf)
			buf.write "</#{name}>"
		end
		
		def write_full_html(buf, content = nil)
			if @closed && content == nil
				write_open_html(buf, true)
			else
				write_open_html(buf)
				buf.write(content)
				write_close_html(buf)
			end
		end
	end
	
end
