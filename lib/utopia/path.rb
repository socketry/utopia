#	This file is part of the "Utopia Framework" project, and is licensed under the GNU AGPLv3.
#	Copyright 2010 Samuel Williams. All rights reserved.
#	See <utopia.rb> for licensing details.

require 'rack/utils'

module Utopia
	
	class Path
		SEPARATOR = "/"

		def initialize(components)
			# To ensure we don't do anything stupid we freeze the components
			@components = components.dup.freeze
		end

		# Shorthand constructor
		def self.[](path)
			create(path)
		end

		def self.create(path)
			case path
			when Path
				return path
			when Array
				return Path.new(path)
			when String
				path = Rack::Utils.unescape(path)
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
			if ext
				File.basename(components.last, ext)
			else
				components.last
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

		def == other
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