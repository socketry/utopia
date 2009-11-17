
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

		def dirname
			path = Path.new(components[0...-1])

			return absolute? ? path.to_absolute : path
		end

		def to_local_path
			components.join(File::SEPARATOR)
		end

		def ascend(&block)
			next_parent = self

			begin
				parent = next_parent
				yield parent
				next_parent = parent.dirname
			end until next_parent.eql?(parent)
		end

		def dup
			return Path.new(components.dup)
		end

		def <=> other
			@components <=> other.components
		end

		def eql? other
			@components.eql?(other.components)
		end

		def hash
			@components.hash
		end
	end
	
end