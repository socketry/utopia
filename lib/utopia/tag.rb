
module Utopia
	
	class Tag
		def initialize(name, attributes = {}, content = nil)
			@name = name
			@attributes = attributes
			@content = nil

			if content
				append(content)
			end
		end

		attr :name
		attr :attributes
		attr :content

		def [](key)
			@attributes[key]
		end

		def append(text)
			@content ||= StringIO.new
			@content.write text
		end

		def to_html
			buf = StringIO.new 
			buf.write "<#{name}"

			@attributes.each do |key, value|
				buf.write " #{key}=\"#{value}\""
			end
			
			buf.write ">"
			buf.write(@content.string) if @content && @content.size > 0
			buf.write "</#{name}>"

			return buf.string
		end

		def to_s
			if @content
				return @content.string
			else
				""
			end
		end
	end
	
end