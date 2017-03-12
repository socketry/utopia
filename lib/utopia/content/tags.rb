# Copyright, 2012, by Samuel G. D. Williams. <http://www.codeotaku.com>
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
	class Content
		# Tags which provide intrinsic behaviour within the content middleware.
		module Tags
			# Invokes a deferred tag from the current state. Works together with {Document::State#defer}.
			# @param id [String] The id of the deferred to invoke.
			class DeferredTag
				def self.call(document, state)
					id = state[:id].to_i
					
					procedure = document.parent.deferred[id]
					
					procedure.call(document, state)
				end
			end
			
			# Invokes a node and renders a single node to the output stream.
			# @param path [String] The path of the node to invoke.
			class NodeTag
				def self.call(document, state)
					path = Path[state[:path]]
					
					node = document.lookup_node(path)
					
					document.render_node(node)
				end
			end
			
			# Renders the content of the parent node into the output of the document.
			class ContentTag
				def self.call(document, state)
					# We are invoking this node within a parent who has content, and we want to generate output equal to that.
					document.write(document.parent.content)
				end
			end
			
			# Tags which can be looked up by name.
			NAMED = {
				'deferred' => DeferredTag,
				'node' => NodeTag,
				'content' => ContentTag
			}
			
			def self.call(name, parent_path)
				NAMED[name]
			end
		end
	end
end
