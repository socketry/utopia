# Copyright, 2017, by Samuel G. D. Williams. <http://www.codeotaku.com>
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

require_relative 'namespace'

module Utopia
	class Content
		# Tags which provide intrinsic behaviour within the content middleware.
		module Tags
			extend Namespace
			
			# Invokes a node and renders a single node to the output stream.
			# @param path [String] The path of the node to invoke.
			tag('node') do |document, state|
				path = Path[state[:path]]
				
				node = document.lookup_node(path)
				
				document.render_node(node)
			end
			
			# Invokes a deferred tag from the current state. Works together with {Document::State#defer}.
			# @param id [String] The id of the deferred to invoke.
			tag('deferred') do |document, state|
				id = state[:id].to_i
				
				deferred = document.parent.deferred[id]
				
				deferred.call(document, state)
			end
			
			# Renders the content of the parent node into the output of the document.
			tag('content') do |document, state|
				# We are invoking this node within a parent who has content, and we want to generate output equal to that.
				document.write(document.parent.content)
			end
			
			# Render the contents only if in the correct environment.
			# @param only [String] A comma separated list of environments to check.
			tag('environment') do |document, state|
				environment = document.attributes.fetch(:environment){RACK_ENV}.to_s
				
				if state[:only].split(',').include?(environment)
					document.parse_markup(state.content)
				end
			end
		end
	end
end
