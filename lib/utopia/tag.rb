
module Utopia
	
	class Tag
		def initialize(name, attributes = {})
			@name = name
			@attributes = attributes
		end

		attr :name
		attr :attributes

		def [](key)
			@attributes[key]
		end

		def append(text)
			@content ||= StringIO.new
			@content.write text
		end

		def to_html(content = nil, buf = StringIO.new)
			to_open_html(buf)
			buf.write(content)
			to_close_html(buf)
			
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
		
		def write_open_html(buf)
			buf ||= StringIO.new 
			buf.write "<#{name}"

			@attributes.each do |key, value|
				buf.write " #{key}=\"#{value}\""
			end
			
			buf.write ">"
		end
		
		def write_close_html(buf)
			buf.write "</#{name}>"
		end
	end
	
end