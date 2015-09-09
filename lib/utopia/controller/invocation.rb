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

require_relative '../http'

module Utopia
	class Controller
		class Invocation
			def self.invoke!(controller_clone, request, path, action, actions)
				invocation = Invocation.new(request, path, action, actions.relative_path)
				
				action.invoke!(controller_clone, request, invocation)
			end
			
			def initialize(request, path, action, relative_path)
				@request = request
				@path = path
				@action = action
				@relative_path = relative_path
			end
			
			attr :path
			attr :action
			attr :relative_path
			
			def matches
				compute_matches_and_mapped!
				
				return @matches
			end
			
			def mapped
				compute_matches_and_mapped!
				
				return @mapped
			end
			
			protected
			
			def compute_matches_and_mapped!
				return if @matches
				
				relative_path = @relative_path.to_a
				path = @action.path.to_a
				
				@matches = []
				@mapped = []
				
				relative_path.zip(path) do |component, pattern|
					if component == pattern
						@mapped << component
					else
						@matches << component
					end
				end
			end
		end
	end
end
