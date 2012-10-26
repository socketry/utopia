#	This file is part of the "Utopia Framework" project, and is released under the MIT license.
#	Copyright 2010 Samuel Williams. All rights reserved.
#	See <utopia.rb> for licensing details.

module Utopia
	
	class Tag
		include Comparable
		
		def <=> other
			if Tag === other
				[@name, @attributes, @closed] <=> [other.name, other.attributes, other.closed]
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
