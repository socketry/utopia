# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2009-2022, by Samuel Williams.

module Utopia
	# Represents a path as an array of path components. Useful for efficient URL manipulation.
	class Path
		include Comparable
		
		SEPARATOR = '/'
		
		def initialize(components = [])
			@components = components
		end
		
		attr_accessor :components
		
		def freeze
			return self if frozen?
			
			@components.freeze
			
			super
		end
		
		def empty?
			@components.empty?
		end
		
		def self.root
			self.new([''])
		end
		
		# Returns the length of the prefix which is shared by two strings.
		def self.prefix_length(a, b)
			[a.size, b.size].min.times{|i| return i if a[i] != b[i]}
		end
		
		# Return the shortest relative path to get to path from root:
		def self.shortest_path(path, root)
			path = self.create(path)
			root = self.create(root).dirname
			
			# Find the common prefix:
			i = prefix_length(path.components, root.components) || 0
			
			# The difference between the root path and the required path, taking into account the common prefix:
			up = root.components.size - i
			
			return self.create([".."] * up + path.components[i..-1])
		end
		
		def shortest_path(root)
			self.class.shortest_path(self, root)
		end
		
		# Converts '+' into whitespace and hex encoded characters into their equivalent characters.
		def self.unescape(string)
			string.tr('+', ' ').gsub(/((?:%[0-9a-fA-F]{2})+)/n) {
				[$1.delete('%')].pack('H*')
			}
		end
		
		def self.[] path
			self.create(path)
		end
		
		def self.split(path)
			case path
			when Path
				return path.to_a
			when Array
				return path
			when String
				create(path).to_a
			else
				[path]
			end
		end
		
		# This constructor takes a string and generates a relative path as efficiently as possible. This is a direct entry point for all controller invocations so it's designed to suit the requirements of that function.
		def self.from_string(string)
			self.new(unescape(string).split(SEPARATOR, -1))
		end
		
		def self.load(value)
			from_string(value) if value
		end
		
		def self.dump(instance)
			instance.to_s if instance
		end
		
		def self.create(path)
			case path
			when Path
				return path
			when Array
				return self.new(path)
			when String
				return self.new(unescape(path).split(SEPARATOR, -1))
			when nil
				return nil
			else
				return self.new([path])
			end
		end
		
		def replace(other_path)
			@components = other_path.components.dup
		end
		
		def include?(*arguments)
			@components.include?(*arguments)
		end
		
		def directory?
			return @components.last == ''
		end
		
		def file?
			return @components.last != ''
		end
		
		def to_directory
			if directory?
				return self
			else
				return self.class.new(@components + [''])
			end
		end
		
		def relative?
			@components.first != ''
		end
		
		def absolute?
			@components.first == ''
		end
		
		def to_absolute
			if absolute?
				return self
			else
				return self.class.new([''] + @components)
			end
		end
		
		def to_relative!
			@components.shift if relative?
		end
		
		def to_str
			if @components == ['']
				SEPARATOR
			else
				@components.join(SEPARATOR)
			end
		end
		
		alias to_s to_str
		
		def to_a
			@components
		end
		
		# @parameter other [Array(String)] The path components to append.
		def join(other)
			# Check whether other is an absolute path:
			if other.first == ''
				self.class.new(other)
			else
				self.class.new(@components + other).simplify
			end
		end
		
		def expand(root)
			root + self
		end
		
		def +(other)
			if other.kind_of? Path
				if other.absolute?
					return other
				else
					return join(other.components)
				end
			elsif other.kind_of? Array
				return join(other)
			elsif other.kind_of? String
				return join(other.split(SEPARATOR, -1))
			else
				return join([other.to_s])
			end
		end
		
		def with_prefix(*arguments)
			self.class.create(*arguments) + self
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
			result = absolute? ? [''] : []
			
			@components.each do |bit|
				if bit == ".."
					result.pop
				elsif bit != "." && bit != ''
					result << bit
				end
			end
			
			result << '' if directory?
			
			return self.class.new(result)
		end
		
		# Returns the first path component.
		def first
			if absolute?
				@components[1]
			else
				@components[0]
			end
		end
		
		# Returns the last path component.
		def last
			if @components != ['']
				@components.last
			end
		end
		
		alias last? file?
		
		# Pops the last path component.
		def pop
			# We don't want to convert an absolute path to a relative path.
			if @components != ['']
				@components.pop
			end
		end
		
		# @return [String] the last path component without any file extension.
		def basename
			basename, _ = @components.last.split('.', 2)
			
			return basename || ''
		end
		
		# @return [String] the last path component's file extension.
		def extension
			_, extension = @components.last.split('.', 2)
			
			return extension
		end
		
		def dirname(count = 1)
			path = self.class.new(@components[0...-count])
			
			return absolute? ? path.to_absolute : path
		end
		
		def local_path(separator = File::SEPARATOR)
			@components.join(separator)
		end
		
		def descend(&block)
			return to_enum(:descend) unless block_given?
			
			components = []
			
			@components.each do |component|
				components << component
				
				yield self.class.new(components.dup)
			end
		end
		
		def ascend(&block)
			return to_enum(:ascend) unless block_given?
			
			components = self.components.dup
			
			while components.any?
				yield self.class.new(components.dup)
				
				components.pop
			end
		end
		
		def split(at)
			if at.kind_of?(String)
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
			self.class.eql?(other.class) and @components.eql?(other.components)
		end
		
		def hash
			@components.hash
		end
		
		def == other
			return false unless other
			
			case other
			when String then self.to_s == other
			when Array then self.to_a == other
			else other.is_a?(self.class) && @components == other.components
			end
		end
		
		def start_with? other
			other.components.each_with_index do |part, index|
				return false if @components[index] != part
			end
			
			return true
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
	
	def self.Path(path)
		Path.create(path)
	end
end
