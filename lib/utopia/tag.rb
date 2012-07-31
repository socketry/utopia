#	This file is part of the "Utopia Framework" project, and is released under the MIT license.
#	Copyright 2010 Samuel Williams. All rights reserved.
#	See <utopia.rb> for licensing details.

module Utopia
	
	class Tag
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
				if value
					buf.write " #{key}=\"#{value}\""
				else
					buf.write " #{key}"
				end
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
