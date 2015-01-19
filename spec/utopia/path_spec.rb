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

require_relative 'spec_helper'

require 'utopia/path'

module Utopia::PathSpec
	describe Utopia::Path do
		it "should concatenate absolute paths" do
			root = Utopia::Path["/"]
			
			expect(root).to be_absolute
			expect(root + Utopia::Path["foo/bar"]).to be == Utopia::Path["/foo/bar"]
		end
		
		it "should compute all descendant paths" do
			root = Utopia::Path["/foo/bar"]
			
			descendants = root.descend.to_a
			
			expect(descendants[0].components).to be == [""]
			expect(descendants[1].components).to be == ["", "foo"]
			expect(descendants[2].components).to be == ["", "foo", "bar"]
			
			ascendants = root.ascend.to_a
			
			expect(descendants.reverse).to be == ascendants
		end
	end
end
