#!/usr/bin/env rspec

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

require 'utopia/content/link'

module Utopia::Content::LinkSpec
	describe Utopia::Content::Link.new(:file, "/foo/bar/baz") do
		it "should link should have full path" do
			expect(subject.name).to be == "baz"
			expect(subject.path).to be == Utopia::Path.create("/foo/bar/baz")
		end
	end
	
	describe Utopia::Content::Link.new(:directory, "/foo/bar/index") do
		it "should link should have full path" do
			expect(subject.name).to be == "bar"
			expect(subject.path).to be == Utopia::Path.create("/foo/bar/index")
		end
	end
	
	describe Utopia::Content::Link.new(:virtual, "bob") do
		it "should link should have full path" do
			expect(subject.name).to be == "bob"
			expect(subject.path).to be == nil
		end
	end
	
	describe Utopia::Content::Links do
		it "should give a list of links" do
			links = Utopia::Content::Links.index(File.expand_path("../links", __FILE__), Utopia::Path.create("/"))
			
			expect(links.size).to be == 3
			
			expect(links[0].kind).to be == :virtual
			expect(links[0].href).to be == nil
			
			expect(links[1].title).to be == "Welcome"
			expect(links[1].to_href).to be == '<a class="link" href="/welcome">Welcome</a>'
			expect(links[1].kind).to be == :file
			expect(links[1].href).to be == "/welcome"
			expect(links[1].name).to be == 'welcome'
			
			expect(links[2].title).to be == 'Foo Bar'
			expect(links[2].kind).to be == :directory
			expect(links[2].href).to be == "/foo/index"
			expect(links[2].name).to be == 'foo'
			
			expect(links[1]).to be_eql links[1]
			expect(links[0]).to_not be_eql links[1]
		end
		
		it "should filter links by name" do
			links = Utopia::Content::Links.index(File.expand_path("../links", __FILE__), Utopia::Path.create("/"), name: /foo/)
			
			expect(links.size).to be == 1
		end
		
		it "should select localized links" do
			root = File.expand_path("../links", __FILE__)
			
			# Select both test links
			links = Utopia::Content::Links.index(root, Utopia::Path.create("/foo"))
			expect(links.size).to be == 2
			
			links = Utopia::Content::Links.index(root, Utopia::Path.create("/foo"), variant: 'en')
			expect(links.size).to be == 1
		end
		
		it "should read correct link order for en" do
			root = File.expand_path("../localized", __FILE__)
			
			# Select both test links
			links = Utopia::Content::Links.index(root, Utopia::Path.create("/"), variant: 'en')
			
			expect(links.collect(&:title)).to be == ['One', 'Two', 'Three', 'Four', 'Five']
		end
		
		it "should read correct link order for zh" do
			root = File.expand_path("../localized", __FILE__)
			
			# Select both test links
			links = Utopia::Content::Links.index(root, Utopia::Path.create("/"), variant: 'zh')
			
			expect(links.collect(&:title)).to be == ['One', 'Two', 'Three', '四']
		end
	end
end
