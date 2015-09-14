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
require_relative '../path/matcher'

module Utopia
	class Controller
		module Rewrite
			def self.prepended(base)
				base.extend(ClassMethods)
			end
			
			class Rule
				def initialize(method, arguments, options, &block)
					@method = method
					@arguments = arguments
					@options = options
					@block = block
				end
				
				attr :method
				attr :arguments
				attr :options
				attr :block
				
				def tr(input, context)
					String(input).tr(*@arguments)
				end
				
				def sub(input, context)
					String(input).sub(*@arguments, &@block)
				end
				
				def gsub(input, context)
					String(input).gsub(*@arguments, &@block)
				end
				
				def match(input, context)
					if match_data = String(input).match(*@arguments)
						if @block
							context.instance_exec(match_data, &@block)
						else
							context.rewrite_match(match_data)
						end
					else
						return input
					end
				end
				
				def prefix(input, context)
					@matcher ||= Path::Matcher.new(@options)
					
					if match_data = @matcher.match(Path[input])
						if @block
							context.instance_exec(match_data, &@block)
						else
							context.rewrite_prefix(match_data)
						end
					else
						return input
					end
				end
				
				def apply(input, context)
					self.send(@method, input, context)
				end
			end
			
			class Rewriter
				def initialize
					@rules = []
				end
				
				def method_missing(name, *arguments, **options, &block)
					@rules << Rule.new(name, arguments, options, &block)
				end
				
				def stop
					throw :stop
				end
				
				def apply(path, context)
					path = original_path = path
					
					# Allow rules to terminate the search:
					catch(:stop) do
						@rules.each do |rule|
							puts "Applying #{rule.method}(#{rule.arguments} #{rule.options}) to #{path}"
							path = rule.apply(path, context)
							
							# If any of the rewrite steps returns nil, we return nil:
							return nil if path == nil
						end
					end
					
					# We only return an updated path if the path changed:
					return path unless path == original_path
				end
			end
			
			module ClassMethods
				def rewrite
					@rewriter ||= Rewriter.new
				end
			end
			
			def rewrite(path)
				# Rewrite the path if possible, may return a String or Path:
				self.class.rewrite.apply(path, self)
			end
			
			def rewrite_match(match_data)
				match_data.names.each do |name|
					self.instance_variable_set("@#{name}", match_data[name])
				end
				
				return match_data.post_match
			end
			
			def rewrite_prefix(match_data)
				rewrite_match(match_data)
			end
			
			# Rewrite the path before processing the request if possible.
			def passthrough(request, path)
				if rewritten_path = rewrite(path)
					rewrite! rewritten_path
				end
				
				super
			end
		end
	end
end
