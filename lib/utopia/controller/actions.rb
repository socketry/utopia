# Copyright, 2016, by Samuel G. D. Williams. <http://www.codeotaku.com>
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
		module Actions
			def self.prepended(base)
				base.extend(ClassMethods)
			end
			
			module ClassMethods
				def actions
					@actions ||= {}
				end
				
				def on(pattern, &block)
					actions[pattern.to_s] = block
				end
				
				def before(&block)
					actions[:before] = block
				end
				
				def after(&block)
					actions[:after] = block
				end
				
				def otherwise(&block)
					actions[:otherwise] = block
				end
				
				def dispatch(controller, request, path)
					if @actions
						name = path.first
						
						if action = @actions[:before]
							controller.instance_exec(request, path, &action)
						end
						
						if action = @actions[name]
							controller.instance_exec(request, path, &action)
						elsif action = @actions[:otherwise]
							controller.instance_exec(request, path, &action)
						end
						
						if action = @actions[:after]
							controller.instance_exec(request, path, &action)
						end
					end
				end
			end
			
			# Rewrite the path before processing the request if possible.
			def passthrough(request, path)
				catch_response do
					self.class.dispatch(self, request, path)
				end || super
			end
		end
	end
end
