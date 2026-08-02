# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2009-2025, by Samuel Williams.

module Utopia
	# Represents a path as an array of path components. Useful for efficient URL manipulation.
	class Path
		include Comparable
		
		SEPARATOR = "/"
		
		# Initialize a path from its individual components.
		# @parameter components [Array(String)] The path components, including empty components that denote leading or trailing separators.
		def initialize(components = [])
			@components = components
		end
		
		attr_accessor :components
		
		# Freeze this object and its internal state.
		# @returns [self] This object.
		def freeze
			return self if frozen?
			
			@components.freeze
			
			super
		end
		
		# Check whether this path has no components.
		# @returns [Boolean] Whether the path has no components.
		def empty?
			@components.empty?
		end
		
		# Construct the root path.
		# @returns [Path] The root path.
		def self.root
			self.new([""])
		end
		
		# Compute the number of leading components shared by two sequences.
		# @parameter a [Array] The first sequence.
		# @parameter b [Array] The second sequence.
		# @returns [Integer | nil] The shared prefix length, or `nil` when every component in the shorter sequence matches.
		def self.prefix_length(a, b)
			[a.size, b.size].min.times{|i| return i if a[i] != b[i]}
		end
		
		# Compute the shortest relative path from the containing directory of `root` to `path`.
		# @parameter path [Path | String | Array] The destination path.
		# @parameter root [Path | String | Array] The source path.
		# @returns [Path] The shortest relative path.
		def self.shortest_path(path, root)
			path = self.create(path)
			root = self.create(root).dirname
			
			# Find the common prefix:
			i = prefix_length(path.components, root.components) || 0
			
			# The difference between the root path and the required path, taking into account the common prefix:
			up = root.components.size - i
			
			return self.create([".."] * up + path.components[i..-1])
		end
		
		# Compute the shortest relative path from the containing directory of `root` to this path.
		# @parameter root [Path | String | Array] The source path.
		# @returns [Path] The shortest relative path.
		def shortest_path(root)
			self.class.shortest_path(self, root)
		end
		
		# Decode URL-encoded path content.
		# @parameter string [String] The encoded content.
		# @returns [String] The decoded content.
		def self.unescape(string)
			string.tr("+", " ").gsub(/((?:%[0-9a-fA-F]{2})+)/n) do
				[$1.delete("%")].pack("H*")
			end
		end
		
		# Coerce the given value into a path.
		# @parameter path [Utopia::Path | String] The path.
		# @returns [Path | nil] The coerced path.
		def self.[] path
			self.create(path)
		end
		
		# Convert a path value into an array of components.
		# @parameter path [Utopia::Path | String] The path.
		# @returns [Array] The path components.
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
		
		# Construct a path from URL-encoded text.
		# @parameter string [String] The encoded path.
		# @returns [Path] The decoded path.
		def self.from_string(string)
			self.new(unescape(string).split(SEPARATOR, -1))
		end
		
		# Load a path from its serialized form.
		# @parameter value [String | nil] The serialized path.
		# @returns [Path | nil] The loaded path.
		def self.load(value)
			from_string(value) if value
		end
		
		# Serialize a path.
		# @parameter instance [Path | nil] The path to serialize.
		# @returns [String | nil] The serialized path.
		def self.dump(instance)
			instance.to_s if instance
		end
		
		# Coerce a value into a path.
		# @parameter path [Path | Array | String | Object | nil] The value to coerce.
		# @returns [Path | nil] The coerced path.
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
		
		# Replace this path's components with a copy of another path's components.
		# @parameter other_path [Path] The replacement path.
		# @returns [Array(String)] The copied components.
		def replace(other_path)
			@components = other_path.components.dup
		end
		
		# Check whether this collection includes the given value.
		# @parameter arguments [Array] The arguments.
		# @returns [Boolean] Whether any component matches the given argument.
		def include?(*arguments)
			@components.include?(*arguments)
		end
		
		# Check whether this path denotes a directory.
		# @returns [Boolean] Whether the path ends with a directory separator.
		def directory?
			return @components.last == ""
		end
		
		# Check whether this path denotes a file.
		# @returns [Boolean] Whether the path ends with a file component.
		def file?
			return @components.last != ""
		end
		
		# Convert this path to a directory path.
		# @returns [Path] A directory path.
		def to_directory
			if directory?
				return self
			else
				return self.class.new(@components + [""])
			end
		end
		
		# Check whether this path is relative.
		# @returns [Boolean] Whether the path is relative.
		def relative?
			@components.first != ""
		end
		
		# Check whether this path is absolute.
		# @returns [Boolean] Whether the path is absolute.
		def absolute?
			@components.first == ""
		end
		
		# Convert this path to an absolute path.
		# @returns [Path] An absolute path.
		def to_absolute
			if absolute?
				return self
			else
				return self.class.new([""] + @components)
			end
		end
		
		# Remove the first component when this path is relative.
		# @returns [String | nil] The removed component, or `nil` when the path is absolute.
		def to_relative!
			@components.shift if relative?
		end
		
		# Convert this object to a string.
		# @returns [String] The resulting string.
		def to_str
			if @components == [""]
				SEPARATOR
			else
				@components.join(SEPARATOR)
			end
		end
		
		alias to_s to_str
		
		# Convert this path to an array of components.
		# @returns [Array] The resulting values.
		def to_a
			@components
		end
		
		# @parameter other [Array(String)] The path components to append.
		# @returns [Path] The joined and simplified path.
		def join(other)
			# Check whether other is an absolute path:
			if other.first == ""
				self.class.new(other)
			else
				self.class.new(@components + other).simplify
			end
		end
		
		# Resolve this path relative to a root path.
		# @parameter root [Path] The root path.
		# @returns [Path] The resolved path.
		def expand(root)
			root + self
		end
		
		# Append path components and return the resulting path.
		# @parameter other [Path | Array | String | Object] The value to append.
		# @returns [Path] The joined and simplified path, or `other` when it is an absolute path.
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
		
		# Prepend a path to this path.
		# @parameter arguments [Array] The arguments accepted by {.create}.
		# @returns [Path] The prefixed path.
		def with_prefix(*arguments)
			self.class.create(*arguments) + self
		end
		
		# Computes the difference of the path.
		# /a/b/c - /a/b -> c
		# a/b/c - a/b -> c
		# @parameter other [Path] The prefix path to remove.
		# @returns [Path] The remaining path.
		def -(other)
			i = 0
			
			while i < other.components.size
				break if @components[i] != other.components[i]
				
				i += 1
			end
			
			return self.class.new(@components[i,@components.size])
		end
		
		# Normalize current-directory, parent-directory, and repeated-separator components.
		# @returns [Path] The normalized path.
		def simplify
			components = []
			
			index = 0
			
			if @components[0] == ""
				components << ""
				index += 1
			end
			
			while index < @components.size
				bit = @components[index]
				if bit == "."
					# No-op (ignore current directory)
				elsif bit == "" && index != @components.size - 1
					# No-op (ignore multiple slashes)
				elsif bit == ".." && components.last && components.last != ".."
					if components.last != ""
						# We can go up one level:
						components.pop
					end
				else
					components << bit
				end
				
				index += 1
			end
			
			return self.class.new(components)
		end
		
		# Return the first path component, excluding the root marker.
		# @returns [String | nil] The first component.
		def first
			if absolute?
				@components[1]
			else
				@components[0]
			end
		end
		
		# Return the last path component, excluding the root marker.
		# @returns [String | nil] The last component.
		def last
			if @components != [""]
				@components.last
			end
		end
		
		alias last? file?
		
		# Remove the last path component without converting the root path to a relative path.
		# @returns [String | nil] The removed component.
		def pop
			# We don't want to convert an absolute path to a relative path.
			if @components != [""]
				@components.pop
			end
		end
		
		# @returns [String] The last path component without its file extension.
		def basename
			basename, _ = @components.last.split(".", 2)
			
			return basename || ""
		end
		
		# @returns [String | nil] The last path component's file extension.
		def extension
			_, extension = @components.last.split(".", 2)
			
			return extension
		end
		
		# Remove trailing path components.
		# @parameter count [Integer] The number of components.
		# @returns [Path] The containing path.
		def dirname(count = 1)
			path = self.class.new(@components[0...-count])
			
			return absolute? ? path.to_absolute : path
		end
		
		# Format this path using a local filesystem separator.
		# @parameter separator [String] The component separator.
		# @returns [String] The local path.
		def local_path(separator = File::SEPARATOR)
			@components.join(separator)
		end
		
		# Enumerate paths from the first component down to this path.
		# @yields {|path| ...} Each successively longer path.
		# @returns [Enumerator | Array] An enumerator when no block is given, otherwise the component array.
		def descend(&block)
			return to_enum(:descend) unless block_given?
			
			components = []
			
			@components.each do |component|
				components << component
				
				yield self.class.new(components.dup)
			end
		end
		
		# Enumerate paths from this path up to its first component.
		# @yields {|path| ...} Each successively shorter path.
		# @returns [Enumerator | nil] An enumerator when no block is given.
		def ascend(&block)
			return to_enum(:ascend) unless block_given?
			
			components = self.components.dup
			
			while components.any?
				yield self.class.new(components.dup)
				
				components.pop
			end
		end
		
		# Split this path around a component or component index.
		# @parameter at [Integer | String] The component index or value at which to split.
		# @returns [Array(Path, Path) | nil] The paths before and after the matched component, or `nil` when it is not found.
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
		
		# Copy this path and its component array.
		# @returns [Path] The copied path.
		def dup
			return Path.new(components.dup)
		end
		
		# Compare this object with another object.
		# @parameter other [Object] The object to compare.
		# @returns [Integer | nil] The comparison result.
		def <=> other
			@components <=> other.components
		end
		
		# Check whether this object is equivalent to another object.
		# @parameter other [Object] The object to compare.
		# @returns [Boolean] Whether the paths have the same class and components.
		def eql? other
			self.class.eql?(other.class) and @components.eql?(other.components)
		end
		
		# Compute the hash value for this object.
		# @returns [Integer] The resulting integer.
		def hash
			@components.hash
		end
		
		# Compare this object with another object.
		# @parameter other [Object] The object to compare.
		# @returns [Boolean] Whether the path is equivalent to the given string, array, or path.
		def == other
			return false unless other
			
			case other
			when String then self.to_s == other
			when Array then self.to_a == other
			else other.is_a?(self.class) && @components == other.components
			end
		end
		
		# Check whether this path starts with the given path.
		# @parameter other [Path] The possible prefix.
		# @returns [Boolean] Whether this path starts with all components of `other`.
		def start_with? other
			other.components.each_with_index do |part, index|
				return false if @components[index] != part
			end
			
			return true
		end
		
		# Fetch one or more path components, excluding root and directory markers from indexing.
		# @parameter index [Integer | Range] The component index or range.
		# @returns [String | Array(String) | nil] The selected component or components.
		def [] index
			return @components[component_offset(index)]
		end
		
		# Replace one or more path components, excluding root and directory markers from indexing.
		# @parameter index [Integer | Range] The component index or range.
		# @parameter value [String | Array(String)] The replacement component or components.
		# @returns [String | Array(String)] The assigned value.
		def []= index, value
			return @components[component_offset(index)] = value
		end
		
		# Delete a path component, excluding root and directory markers from indexing.
		# @parameter index [Integer] The component index.
		# @returns [String | nil] The deleted component.
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
	
	# Coerce a value into a {Path}.
	# @parameter path [Utopia::Path | String] The path.
	# @returns [Path | nil] The coerced path.
	def self.Path(path)
		Path.create(path)
	end
end
