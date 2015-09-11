# Copyright, 2014, by Samuel G. D. Williams. <http://www.codeotaku.com>
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

require_relative '../http'

module Utopia
	class Controller
		module Rewrite
			def self.prepended(base)
				base.extend(ClassMethods)
			end
			
			module ClassMethods
				def patterns
					@patterns ||= []
				end
				
				def rewrite(pattern, &block)
					patterns << [pattern, block]
				end
			end
			
			def patterns
				self.class.patterns
			end
			
			def rewrite_matched(match)
				match.names.each do |name|
					self.instance_variable_set("@#{name}", match[name])
				end
				
				return match.post_match
			end
			
			def rewrite(path)
				path = original_path = path.to_s
				
				patterns.each do |pattern, block|
					if match_data = path.match(pattern)
						if block
							path = self.instance_exec(match_data, &block)
						else
							path = self.rewrite_matched(match_data)
						end
					end
					
					# If any of the rewrite steps returns nil, we return nil:
					return nil if path == nil
				end
				
				# We only return an updated path if the path changed:
				return path unless path == original_path
			end
			
			# Rewrite the path before processing the request if possible.
			def process!(request, path)
				if path = rewrite(path)
					rewrite! path
				else
					super
				end
			end
		end
	end
end
