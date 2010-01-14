
class String
	HTML_ESCAPE = {"&" => "&amp;", "<" => "&lt;", ">" => "&gt;", "\"" => "&quot;"}
	HTML_ESCAPE_PATTERN = Regexp.new("[" + Regexp.quote(HTML_ESCAPE.keys.join) + "]")

	def to_html
		gsub(HTML_ESCAPE_PATTERN){|c| HTML_ESCAPE[c]}
	end

	def to_title
		(" " + self).gsub(/[ \-_](.)/){" " + $1.upcase}
	end

	def to_snake
		self.gsub("::", "").gsub(/([A-Z]+)/){"_" + $1.downcase}.sub(/^_+/, "")
	end
end

class Hash
	def symbolize_keys
		inject({}) do |options, (key, value)|
			options[(key.to_sym rescue key) || key] = value
			options
		end
	end
end

class Rack::Request
	def self.new(*args)
		super(*args)
	end
end