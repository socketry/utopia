# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2015-2025, by Samuel Williams.

require "utopia/content/links"

describe Utopia::Content::Links do
	let(:root) {File.expand_path("links", __dir__)}
	let(:links) {subject.new(root)}
	
	with "#index_filter" do
		it "should match index" do
			expect(links.index_filter).to be =~ "index.xnode"
		end
		
		it "should not match invalid index" do
			expect(links.index_filter).not.to be =~ "old-index.xnode"
		end
	end
	
	with "matching name" do
		it "can match named link" do
			matched = links.index("/", name: "welcome")
			
			expect(matched.size).to be == 1
			expect(matched[0].name).to be == "welcome"
		end
		
		it "doesn't match partial names" do
			matched = links.index("/", name: "come")
			
			expect(matched).to be(:empty?) 
		end
	end
	
	with "name filter" do
		it "should filter links by name" do
			matched = links.index("/", name: /foo/)
			
			expect(matched.size).to be == 1
		end
	end
	
	with "without locale" do
		it "should index all links" do
			matched = links.index("/foo").sort_by(&:locale)
			expect(matched.size).to be == 2
			
			expect(matched[0].name).to be == "test"
			expect(matched[0].locale).to be == "de"
			
			expect(matched[1].name).to be == "test"
			expect(matched[1].locale).to be == "en"
		end
	end
	
	with "locale" do
		it "should select localized links" do
			matched = links.index("/foo", locale: "en")
			expect(matched.size).to be == 1
			
			expect(matched[0].name).to be == "test"
			expect(matched[0].locale).to be == "en"
		end
	end
	
	with "localized links"  do
		let(:root) {File.expand_path("localized", __dir__)}
		
		it "should read correct link order for en" do
			matched = links.index("/", locale: "en")
			
			expect(matched.collect(&:title)).to be == ["One", "Two", "Three", "Four", "Five"]
		end
		
		it "should read correct link order for zh" do
			matched = links.index("/", locale: "zh")
			
			expect(matched.collect(&:title)).to be == ["One", "Two", "Three", "四"]
		end
	end
	
	with "#index" do
		it "should give a list of links" do
			matched = links.index("/")
			
			expect(matched.size).to be == 4
			
			expect(matched[0]).to have_attributes(
				title: be == "Welcome",
				kind: be == :file,
				name: be == "welcome",
				locale: be_nil,
				path: be == ["", "welcome"],
				href: be == "/welcome",
				to_href: be == '<a class="link" href="/welcome">Welcome</a>'
			)
			
			expect(matched[1]).to have_attributes(
				title: be == "Foo Bar",
				kind: be == :directory,
				name: be == "foo",
				locale: be_nil,
				path: be == ["", "foo", "index"],
				href: be == "/foo/index",
				to_href: be == '<a class="link" href="/foo/index">Foo Bar</a>'
			)
			
			expect(matched[2]).to have_attributes(
				title: be == "Bar",
				kind: be == :directory,
				name: be == "bar",
				locale: be_nil,
				path: be == ["", "bar", "index"],
				href: be == "/bar/index",
				to_href: be == '<a class="link" href="/bar/index">Bar</a>'
			)
			
			expect(matched[3]).to have_attributes(
				title: be == "Redirect",
				kind: be == :directory,
				name: be == "redirect",
				locale: be_nil,
				path: be == ["", "redirect", ""],
				href: be == "https://www.codeotaku.com",
				to_href: be == '<a class="link" href="https://www.codeotaku.com">Redirect</a>'
			)
			
			expect(matched[0]).to be == matched[0]
			expect(matched[0]).not.to be == matched[1]
		end
		
		it "can list directories" do
			matched = links.index("/bar")
			
			expect(matched.size).to be == 1
			
			expect(matched[0]).to have_attributes(
				title: be == "Parent?",
				kind: be == :directory,
				name: be == "parent",
				locale: be_nil,
				path: be == ["", "bar", "parent", ""],
				href: be_nil,
				to_href: be == '<span class="link">Parent?</span>'
			)
		end
		
		it "can list directories with multiple localized indexes" do
			matched = links.index("/bar/parent").sort_by(&:locale)
			
			expect(matched.size).to be == 2
			
			expect(matched[0].title).to be == "Child"
			expect(matched[0].kind).to be == :directory
			expect(matched[0].name).to be == "child"
			expect(matched[0].locale).to be == "en"
			expect(matched[0].path).to be == ["", "bar", "parent", "child", "index"]
			
			expect(matched[1].title).to be == "Child"
			expect(matched[1].kind).to be == :directory
			expect(matched[1].name).to be == "child"
			expect(matched[1].locale).to be == "ja"
			expect(matched[1].path).to be == ["", "bar", "parent", "child", "index"]
		end
		
		it "can get title of /index" do
			matched = links.index("/", indices: true, name: "index")
			
			expect(matched.size).to be == 1
			
			link = matched.first
			
			expect(link.title).to be == "Home"
		end
		
		it "can get title of /foo/index" do
			matched = links.index("/foo", indices: true, name: "index")
			
			expect(matched.size).to be == 1
			
			link = matched.first
			
			expect(link.title).to be == "Foo Bar"
		end
		
		it "can get title of /bar/index" do
			matched = links.index("/bar", indices: true, name: "index")
			
			expect(matched.size).to be == 1
			
			link = matched.first
			
			expect(link.title).to be == "Bar"
		end
	end
	
	with "#for" do
		it "can get title of /index" do
			link = links.for(Utopia::Path["/index"])
			expect(link.title).to be == "Home"
		end
		
		it "can get title of /foo/index" do
			link = links.for(Utopia::Path["/foo/index"])
			expect(link.title).to be == "Foo Bar"
		end
		
		it "can get title of /bar/index" do
			link = links.for(Utopia::Path["/bar/index"])
			expect(link.title).to be == "Bar"
		end
	end
end
