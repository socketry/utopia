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

require_relative '../spec_helper'

require 'utopia/content'

module Utopia::ContentSpec
	describe Utopia::Content::Node do
		let(:root) {File.expand_path("../node", __FILE__)}
		let(:content) {Utopia::Content.new(lambda{}, root: root)}
		
		it "should list siblings in correct order" do
			node = content.lookup_node(Utopia::Path['/ordered/first'])
			
			links = node.sibling_links
			
			expect(links.size).to be == 2
			expect(links[0].name).to be == 'first'
			expect(links[1].name).to be == 'second'
		end
		
		it "should list all links in correct order" do
			node = content.lookup_node(Utopia::Path['/ordered/index'])
			
			links = node.links
			
			expect(links.size).to be == 2
			expect(links[0].name).to be == 'first'
			expect(links[1].name).to be == 'second'
		end
		
		it "shoud list related links" do
			node = content.lookup_node(Utopia::Path['/related/foo.en'])
			
			links = node.related_links
			
			expect(links.size).to be == 2
			expect(links[0].name).to be == 'foo.en'
			expect(links[0].locale).to be == 'en'
			
			expect(links[1].name).to be == 'foo.jp'
			expect(links[1].locale).to be == 'jp'
		end
	end
end