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
	class Basename
		# A basename represents a file name with an optional extension. You can specify a specific extension to identify or specify '.' to select any extension after the last trailing dot.
		def initialize(name, extension = false)
			if extension and offset = name.rindex(extension)
				@name = name[0...offset]
				@extension = name[offset..-1]
			else
				@name = name
				@extension = nil
			end
		end
		
		def rename(name)
			copy = self.dup
			
			copy.send(:instance_variable_set, :@name, name)
			
			return copy
		end
		
		attr :name
		attr :extension
		
		# Used for identifying locale information if present:
		def parts
			@parts ||= @name.split('.')[1..-1]
		end
		
		def locale
			parts.last
		end
		
		def to_str
			"#{name}#{extension}"
		end
		
		def to_s
			to_str
		end
	end
	
	class Path
		SEPARATOR = "/"

		include Comparable

		def initialize(components = [])
			@components = components
		end

		def freeze
			@components.freeze
			
			super
		end

		def self.unescape(string)
			string.tr('+', ' ').gsub(/((?:%[0-9a-fA-F]{2})+)/n) {
				[$1.delete('%')].pack('H*')
			}
		end

		def self.[] path
			self.create(path)
		end

		def self.create(path)
			case path
			when Path
				return path
			when Array
				return self.new(path)
			when String
				return self.new(unescape(path).split(SEPARATOR, -1))
			when Symbol
				return self.new([path])
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
				return self.class.new([""] + @components)
			end
		end

		def to_str
			if @components == [""]
				SEPARATOR
			else
				@components.join(SEPARATOR)
			end
		end

		def to_s
			to_str
		end

		def join(other)
			self.class.new(@components + other).simplify
		end

		def expand(root)
			root + self
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
			
			return self.class.new(@components[i,@components.size])
		end

		def simplify
			result = absolute? ? [""] : []

			@components.each do |bit|
				if bit == ".."
					result.pop
				elsif bit != "." && bit != ""
					result << bit
				end
			end

			result << "" if directory?
			
			return self.class.new(result)
		end

		def basename(*args)
			Basename.new(@components.last, *args)
		end
		
		def dirname(count = 1)
			path = self.class.new(@components[0...-count])

			return absolute? ? path.to_absolute : path
		end

		def to_local_path(separator = File::SEPARATOR)
			@components.join(separator)
		end

		def descend(&block)
			return to_enum(:descend) unless block_given?
			
			parent_path = []
			
			@components.each do |component|
				parent_path << component
				
				yield self.class.new(parent_path.dup)
			end
		end

		def ascend(&block)
			return to_enum(:ascend) unless block_given?
			
			next_parent = self
			
			begin
				parent = next_parent
				
				yield parent
				
				next_parent = parent.dirname
			end until next_parent.eql?(parent)
		end

		def split(at)
			if at.kind_of? String
				at = @components.index(at)
			end
			
			if at
				return [self.class.new(@components[0...at]), self.class.new(@components[at+1..-1])]
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

		def start_with? other
			other.components.each_with_index do |part, index|
				return false if @components[index] != part
			end
			
			return true
		end
		
		def hash
			@components.hash
		end
		
		def [] index
			return @components[component_offset(index)]
		end
		
		# Replaces a named component, indexing as per 
		def []= index, value
			return @components[component_offset(index)] = value
		end
		
		def delete_at(index)
			@components.delete_at(component_offset(index))
		end
		
		def first
			if absolute?
				@components[1]
			else
				@components[0]
			end
		end
		
		def last
			if directory?
				@components[-2]
			else
				@components[-1]
			end
		end
		
		private
		
		# We adjust the index slightly so that indices reference path components rather than the directory markers at the start and end of the path components array.
		def component_offset(index)
			if Range === index
				Range.new(adjust_index(index.first), adjust_index(index.last), index.exclude_end?)
			else
				adjust_index(index)
			end
		end
		
		def adjust_index(index)
			if index < 0
				index -= 1 if directory?
			else
				index += 1 if absolute?
			end
			
			return index
		end
	end
	
	def Path(path)
		Path.create(path)
	end
end
