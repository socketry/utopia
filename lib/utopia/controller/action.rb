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

module Utopia
	class Controller
		class Action < Hash
			attr_accessor :callback
			attr_accessor :options
			
			def callback?
				@callback != nil
			end
			
			def indirect?
				@options[:indirect]
			end
			
			def eql? other
				super and self.callback.eql? other.callback and self.options.eql? other.options
			end
			
			def hash
				[super, callback, options].hash
			end
			
			def == other
				super and (self.callback == other.callback) and (self.options == other.options)
			end
			
			protected
			
			def append(path, index, actions = [])
				# ** is greedy, it always matches if possible:
				if match_all = self[:**]
					# Match all remaining input:
					actions << match_all if match_all.callback?
				end
				
				if index < path.size
					name = path[index].to_sym
				
					if match_name = self[name]
						# Match the exact name:
						match_name.append(path, index+1, actions)
					end
					
					if match_one = self[:*]
						# Match one input:
						match_one.append(path, index+1, actions)
					end
				else
					# Got to end, matched completely:
					actions << self if self.callback?
				end
			end
			
			public
			
			# relative_path = 2014/mr-potato
			# actions => {:** => A}
			def select(relative_path)
				actions = []
				
				append(relative_path.reverse, 0, actions)
				
				# puts "select(#{relative_path}, #{self.inspect}) => #{actions.inspect}"
				
				return actions
			end
			
			def define(path, options = {}, &callback)
				current = self
				
				path.reverse.each do |name|
					current = (current[name.to_sym] ||= Action.new)
				end
				
				current.options = options
				current.callback = callback
				
				return current
			end
			
			def invoke!(controller, *arguments)
				if @options[:unbound]
					# This is the old code path for explicit methods.
					controller.instance_exec(controller, *arguments, &@callback)
				else
					controller.instance_exec(*arguments, &@callback)
				end
			end
			
			def inspect
				if callback?
					"<action " + super + ":#{callback.source_location}(#{options})>"
				else
					"<action " + super + ">"
				end
			end
		end
	end
end
