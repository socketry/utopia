#!/usr/bin/env rspec
# frozen_string_literal: true

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

require 'utopia/content/links'

RSpec.describe Utopia::Content::Links do
	let(:root) {File.expand_path("links", __dir__)}
	subject {described_class.new(root)}
	
	describe '#index_filter' do
		it "should match index" do
			expect("index.xnode").to match(subject.index_filter)
		end
		
		it "should not match invalid index" do
			expect("old-index.xnode").to_not match(subject.index_filter)
		end
	end
	
	it "should not match partial strings" do
		links = subject.index(Utopia::Path.create("/"), name: "come")
		
		expect(links).to be_empty
	end
	
	it "should give a list of links" do
		links = subject.index(Utopia::Path.create("/"))
		
		expect(links.size).to be == 3
		
		expect(links[0].title).to be == "Welcome"
		expect(links[0].to_href).to be == '<a class="link" href="/welcome">Welcome</a>'
		expect(links[0].kind).to be == :file
		expect(links[0].href).to be == "/welcome"
		expect(links[0].name).to be == 'welcome'
		
		expect(links[1].title).to be == 'Foo Bar'
		expect(links[1].kind).to be == :directory
		expect(links[1].href).to be == "/foo/index"
		expect(links[1].name).to be == 'foo'
		
		expect(links[1]).to be_eql links[1]
		expect(links[0]).to_not be_eql links[1]
	end
	
	it "should filter links by name" do
		links = subject.index(Utopia::Path.create("/"), name: /foo/)
		
		expect(links.size).to be == 1
	end
	
	it "should select localized links" do
		# Select both test links
		links = subject.index(Utopia::Path.create("/foo"))
		expect(links.size).to be == 2
		
		links = subject.index(Utopia::Path.create("/foo"), locale: 'en')
		expect(links.size).to be == 1
	end
	
	context 'with localized links'  do
		let(:root) {File.expand_path("localized", __dir__)}
		
		it "should read correct link order for en" do
			links = subject.index(Utopia::Path.create("/"), locale: 'en')
			
			expect(links.collect(&:title)).to be == ['One', 'Two', 'Three', 'Four', 'Five']
		end
		
		it "should read correct link order for zh" do
			links = subject.index(Utopia::Path.create("/"), locale: 'zh')
			
			expect(links.collect(&:title)).to be == ['One', 'Two', 'Three', '四']
		end
	end
	
	describe '#index' do
		it "can get title of /index" do
			links = subject.index(Utopia::Path.create("/"), indices: true, name: "index")
			
			expect(links.size).to be 1
			
			link = links.first
			
			expect(link.title).to be == "Home"
		end
		
		it "can get title of /foo/index" do
			links = subject.index(Utopia::Path.create("/foo"), indices: true, name: "index")
			
			expect(links.size).to be 1
			
			link = links.first
			
			expect(link.title).to be == "Foo Bar"
		end
		
		it "can get title of /bar/index" do
			links = subject.index(Utopia::Path.create("/bar"), indices: true, name: "index")
			
			expect(links.size).to be 1
			
			link = links.first
			
			expect(link.title).to be == "Bar"
		end
	end
	
	describe '#for' do
		it "can get title of /index" do
			link = subject.for(Utopia::Path.create("/index"))
			expect(link.title).to be == "Home"
		end
		
		it "can get title of /foo/index" do
			link = subject.for(Utopia::Path.create("/foo/index"))
			expect(link.title).to be == "Foo Bar"
		end
		
		it "can get title of /bar/index" do
			link = subject.for(Utopia::Path.create("/bar/index"))
			expect(link.title).to be == "Bar"
		end
	end
end
