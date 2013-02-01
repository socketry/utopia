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
	
	class Path
		SEPARATOR = "/"

		include Comparable

		def initialize(components = [])
			# To ensure we don't do anything stupid we freeze the components
			@components = components.dup.freeze
		end

		# Shorthand constructor
		def self.[](path)
			create(path)
		end

		def self.unescape(string)
			string.tr('+', ' ').gsub(/((?:%[0-9a-fA-F]{2})+)/n) {
				[$1.delete('%')].pack('H*')
			}
		end

		def self.create(path)
			case path
			when Path
				return path
			when Array
				return Path.new(path)
			when String
				path = unescape(path)
				# Ends with SEPARATOR
				if path[-1,1] == SEPARATOR
					return Path.new(path.split(SEPARATOR) << "")
				else
					return Path.new(path.split(SEPARATOR))
				end
			end
		end

		attr :components

		def directory?
			return @components.last == ""
		end

		def to_directory
			if directory?
				return self
			else
				return join([""])
			end
		end

		def absolute?
			return @components.first == ""
		end

		def to_absolute
			if absolute?
				return self
			else
				return Path.new([""] + @components)
			end
		end

		def to_s
			if @components == [""]
				SEPARATOR
			else
				@components.join(SEPARATOR)
			end
		end

		def join(other)
			Path.new(@components + other).simplify
		end

		def +(other)
			if other.kind_of? Array
				return join(other)
			elsif other.kind_of? Path
				if other.absolute?
					return other
				else
					return join(other.components)
				end
			else
				return join([other.to_s])
			end
		end

		# Computes the difference of the path.
		# /a/b/c - /a/b -> c
		# a/b/c - a/b -> c
		def -(other)
			i = 0
			
			while i < other.components.size
				break if @components[i] != other.components[i]
				
				i += 1
			end
			
			return Path.create(@components[i,@components.size])
		end

		def simplify
			result = absolute? ? [""] : []

			components.each do |bit|
				if bit == ".."
					result.pop
				elsif bit != "." && bit != ""
					result << bit
				end
			end

			result << "" if directory?
			return Path.new(result)
		end

		def basename(ext = nil)
			if ext == true
				File.basename(components.last, extension)
			elsif String === ext
				File.basename(components.last, ext)
			else
				components.last
			end
		end

		def extension
			if components.last
				components.last.split(".").last
			else
				nil
			end
		end

		def dirname(count = 1)
			path = Path.new(components[0...-count])

			return absolute? ? path.to_absolute : path
		end

		def to_local_path
			components.join(File::SEPARATOR)
		end

		def ascend(&block)
			paths = []
			
			next_parent = self

			begin
				parent = next_parent
				
				yield parent if block_given?
				paths << parent
				
				next_parent = parent.dirname
			end until next_parent.eql?(parent)
			
			return paths
		end

		def split(at)
			if at.kind_of? String
				at = @components.index(at)
			end
			
			if at
				return [Path.new(@components[0...at]), Path.new(@components[at+1..-1])]
			else
				return nil
			end
		end

		def dup
			return Path.new(components.dup)
		end

		def <=> other
			@components <=> other.components
		end

		def eql? other
			if self.class == other.class
				return @components.eql?(other.components)
			else
				return false
			end
		end

		def starts_with? other
			other.components.each_with_index do |part, index|
				return false if @components[index] != part
			end
			
			return true
		end

		def hash
			@components.hash
		end

		def last
			if directory?
				components[-2]
			else
				components[-1]
			end
		end

		def self.locale(name, extension = false)
			if String === extension
				name = File.basename(name, extension)
			elsif extension
				name = name.split
			end
			
			name.split(".")[1..-1].join(".")
		end
		
		def locale (extension = false)
			return Path.locale(last, extension)
		end
	end
	
end