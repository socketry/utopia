#!/usr/bin/env rspec
# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2015-2022, by Samuel Williams.

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
	
	context 'matching name' do
		it "can match named link" do
			links = subject.index("/", name: "welcome")
			
			expect(links.size).to be == 1
			expect(links[0].name).to be == "welcome"
		end
		
		it "doesn't match partial names" do
			links = subject.index("/", name: "come")
			
			expect(links).to be_empty
		end
	end
	
	context 'with name filter' do
		it "should filter links by name" do
			links = subject.index("/", name: /foo/)
			
			expect(links.size).to be == 1
		end
	end
	
	context 'without locale' do
		it "should index all links" do
			links = subject.index("/foo").sort_by(&:locale)
			expect(links.size).to be == 2
			
			expect(links[0].name).to be == "test"
			expect(links[0].locale).to be == "de"
			
			expect(links[1].name).to be == "test"
			expect(links[1].locale).to be == "en"
		end
	end
	
	context 'with locale' do
		it "should select localized links" do
			links = subject.index("/foo", locale: 'en')
			expect(links.size).to be == 1
			
			expect(links[0].name).to be == "test"
			expect(links[0].locale).to be == "en"
		end
	end
	
	context 'with localized links'  do
		let(:root) {File.expand_path("localized", __dir__)}
		
		it "should read correct link order for en" do
			links = subject.index("/", locale: 'en')
			
			expect(links.collect(&:title)).to be == ['One', 'Two', 'Three', 'Four', 'Five']
		end
		
		it "should read correct link order for zh" do
			links = subject.index("/", locale: 'zh')
			
			expect(links.collect(&:title)).to be == ['One', 'Two', 'Three', '四']
		end
	end
	
	describe '#index' do
		it "should give a list of links" do
			links = subject.index("/")
			
			expect(links.size).to be == 4
			
			expect(links[0].title).to be == "Welcome"
			expect(links[0].kind).to be == :file
			expect(links[0].name).to be == 'welcome'
			expect(links[0].locale).to be_nil
			expect(links[0].path).to be == ['', 'welcome']
			expect(links[0].href).to be == "/welcome"
			expect(links[0].to_href).to be == '<a class="link" href="/welcome">Welcome</a>'
			
			expect(links[1].title).to be == 'Foo Bar'
			expect(links[1].kind).to be == :directory
			expect(links[1].name).to be == 'foo'
			expect(links[1].locale).to be_nil
			expect(links[1].path).to be == ['', 'foo', 'index']
			expect(links[1].href).to be == "/foo/index"
			
			expect(links[2].title).to be == 'Bar'
			expect(links[2].kind).to be == :directory
			expect(links[2].name).to be == 'bar'
			expect(links[2].locale).to be_nil
			expect(links[2].path).to be == ['', 'bar', 'index']
			expect(links[2].href).to be == "/bar/index"
			
			expect(links[3].title).to be == 'Redirect'
			expect(links[3].kind).to be == :directory
			expect(links[3].name).to be == 'redirect'
			expect(links[3].locale).to be_nil
			expect(links[3].path).to be == ['', 'redirect', '']
			expect(links[3].href).to be == "https://www.codeotaku.com"
			
			expect(links[1]).to be_eql links[1]
			expect(links[0]).to_not be_eql links[1]
		end
		
		it "can list directories" do
			links = subject.index("/bar")
			
			expect(links.size).to be == 1
			
			expect(links[0].title).to be == "Parent?"
			expect(links[0].kind).to be == :directory
			expect(links[0].name).to be == "parent"
			expect(links[0].locale).to be_nil
			expect(links[0].path).to be == ['', 'bar', 'parent', '']
		end
		
		it "can list directories with multiple localized indexes" do
			links = subject.index("/bar/parent").sort_by(&:locale)
			
			expect(links.size).to be == 2
			
			expect(links[0].title).to be == "Child"
			expect(links[0].kind).to be == :directory
			expect(links[0].name).to be == "child"
			expect(links[0].locale).to be == 'en'
			expect(links[0].path).to be == ['', 'bar', 'parent', 'child', 'index']
			
			expect(links[1].title).to be == "Child"
			expect(links[1].kind).to be == :directory
			expect(links[1].name).to be == "child"
			expect(links[1].locale).to be == 'ja'
			expect(links[1].path).to be == ['', 'bar', 'parent', 'child', 'index']
		end
		
		it "can get title of /index" do
			links = subject.index("/", indices: true, name: "index")
			
			expect(links.size).to be 1
			
			link = links.first
			
			expect(link.title).to be == "Home"
		end
		
		it "can get title of /foo/index" do
			links = subject.index("/foo", indices: true, name: "index")
			
			expect(links.size).to be 1
			
			link = links.first
			
			expect(link.title).to be == "Foo Bar"
		end
		
		it "can get title of /bar/index" do
			links = subject.index("/bar", indices: true, name: "index")
			
			expect(links.size).to be 1
			
			link = links.first
			
			expect(link.title).to be == "Bar"
		end
	end
	
	describe '#for' do
		it "can get title of /index" do
			link = subject.for(Utopia::Path["/index"])
			expect(link.title).to be == "Home"
		end
		
		it "can get title of /foo/index" do
			link = subject.for(Utopia::Path["/foo/index"])
			expect(link.title).to be == "Foo Bar"
		end
		
		it "can get title of /bar/index" do
			link = subject.for(Utopia::Path["/bar/index"])
			expect(link.title).to be == "Bar"
		end
	end
end
