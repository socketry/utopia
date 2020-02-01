# frozen_string_literal: true

# Copyright, 2015, by Samuel G. D. Williams. <http://www.codeotaku.com>
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

require_relative '../path'

module Utopia
	class Path
		# Performs structured, efficient, matches against {Path} instances. Supports regular expressions, type-casts and constants.
		# @example
		# 	path = Utopia::Path['users/20/edit']
		# 	matcher = Utopia::Path::Matcher[users: /users/, id: Integer, action: String]
		# 	match_data = matcher.match(path)
		class Matcher
			# The result of matching against a {Path}.
			class MatchData
				def initialize(named_parts, post_match)
					@named_parts = named_parts
					@post_match = Path[post_match]
				end
				
				# Matched components by name.
				attr :named_parts
				
				# Any remaining part past the end of the explicitly matched components.
				attr :post_match
				
				def [] key
					@named_parts[key]
				end
				
				def names
					@named_parts.keys
				end
			end
			
			# @param patterns [Hash<Symbol,Pattern>] An ordered list of things to match.
			def initialize(patterns = [])
				@patterns = patterns
			end
			
			def self.[](patterns)
				self.new(patterns)
			end
			
			def coerce(klass, value)
				if klass == Integer
					Integer(value)
				elsif klass == Float
					Float(value)
				elsif klass == String
					value.to_s
				else
					klass.new(value)
				end
			rescue
				return nil
			end
			
			# This is a path prefix matching algorithm. The pattern is an array of String, Symbol, Regexp, or nil. The path is an array of String.
			def match(path)
				components = path.to_a
				
				# Can't possibly match if not enough components:
				return nil if components.size < @patterns.size
				
				named_parts = {}
				
				# Try to match each component against the pattern:
				@patterns.each_with_index do |(key, pattern), index|
					component = components[index]
					
					if pattern.is_a? Class
						return nil unless value = coerce(pattern, component)
						
						named_parts[key] = value
					elsif pattern
						if result = pattern.match(component)
							named_parts[key] = result
						else
							# Couldn't match:
							return nil
						end
					else
						# Ignore this part:
						named_parts[key] = component
					end
				end
				
				return MatchData.new(named_parts, components[@patterns.size..-1])
			end
		end
	end
end
