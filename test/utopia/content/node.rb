# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2015-2026, by Samuel Williams.

require "utopia/content"

describe Utopia::Content::Node do
	let(:root) {File.expand_path("node", __dir__)}
	let(:content) {Utopia::Content.new(Protocol::HTTP::Middleware::NotFound, root: root)}
	
	it "should list siblings in correct order" do
		node = content.lookup_node(Utopia::Path["/ordered/first"])
		
		links = node.sibling_links
		
		expect(links.size).to be == 2
		expect(links[0].name).to be == "first"
		expect(links[1].name).to be == "second"
	end
	
	it "should list all links in correct order" do
		node = content.lookup_node(Utopia::Path["/ordered/index"])
		
		links = node.links
		
		expect(links.size).to be == 2
		expect(links[0].name).to be == "first"
		expect(links[1].name).to be == "second"
	end
	
	it "should enumerate links" do
		node = content.lookup_node(Utopia::Path["/ordered/index"])
		names = []
		
		result = node.links do |link|
			names << link.name
		end
		
		expect(names).to be == ["first", "second"]
		expect(result).to be == node.links
	end
	
	it "should list related links" do
		node = content.lookup_node(Utopia::Path["/related/foo"], "en")
		
		links = node.related_links
		
		expect(links.size).to be == 2
		expect(links[0].name).to be == "foo"
		expect(links[0].locale).to be == "en"
		
		expect(links[1].name).to be == "foo"
		expect(links[1].locale).to be == "ja"
	end
	
	it "should look up node by path" do
		node = content.lookup_node(Utopia::Path["/lookup/index"])
		
		response = node.process!(nil)
		
		expect(response.status).to be == 200
		expect(response.headers["content-type"]).to be == "text/html; charset=utf-8"
		expect(response.read).to be == "<p>Hello World</p>"
	end
	
	with "#local_path" do
		let(:base) {Pathname.new(root)}
		
		it "can compute relative path from index node" do
			node = content.lookup_node(Utopia::Path["/ordered/index"])
			
			expect(node.local_path("preview.jpg")).to be == (base + "ordered/preview.jpg")
		end
		
		it "can compute relative path from named node" do
			node = content.lookup_node(Utopia::Path["/ordered/first"])
			
			expect(node.local_path("preview.jpg")).to be == (base + "ordered/preview.jpg")
		end
		
		it "can compute absolute paths" do
			node = content.lookup_node(Utopia::Path["/ordered/index"])
			
			expect(node.local_path("/shared/preview.jpg")).to be == (base + "shared/preview.jpg")
		end
		
		it "rejects absolute paths which escape the content root" do
			node = content.lookup_node(Utopia::Path["/ordered/index"])
			
			expect do
				node.local_path("/../../outside")
			end.to raise_exception(ArgumentError, message: be =~ /escapes the specified root/)
		end
		
		it "contains relative paths within the content root" do
			node = content.lookup_node(Utopia::Path["/ordered/index"])
			
			expect(node.local_path("../../../outside")).to be == (base + "outside")
		end
	end
	
	with "#relative_path" do
		it "can compute relative path from index node" do
			node = content.lookup_node(Utopia::Path["/ordered/index"])
			
			expect(node.relative_path("preview.jpg")).to be == (Utopia::Path["/ordered/preview.jpg"])
		end
		
		it "can compute relative path from named node" do
			node = content.lookup_node(Utopia::Path["/ordered/first"])
			
			expect(node.relative_path("preview.jpg")).to be == (Utopia::Path["/ordered/preview.jpg"])
		end
	end
	
	it "exposes its name" do
		node = content.lookup_node(Utopia::Path["/ordered/first"])
		
		expect(node.name).to be == "first"
	end
	
	it "uses the containing directory for index siblings" do
		node = content.lookup_node(Utopia::Path["/ordered/index"])
		
		expect(node.siblings_path).to be == Utopia::Path.root
	end
	
	it "exposes rendering context" do
		deferred = []
		linked = []
		
		node = Object.new
		node.define_singleton_method(:links) do |*arguments, **options, &block|
			block&.call(:link)
			linked << [arguments, options]
			return :links
		end
		
		state = Struct.new(:node, :attributes) do
			define_method(:defer) do |&block|
				deferred << block
				return :deferred
			end
		end.new(node, {local: "Local"})
		
		document = Struct.new(:controller, :localization, :request, :attributes, :content, :parent, :first).new(
			:controller,
			:localization,
			:request,
			{global: "Global"},
			:content,
			:parent,
			:first,
		)
		context = subject::Context.new(document, state)
		
		expect(context.partial{:content}).to be == :deferred
		expect(deferred.first.call).to be == :content
		expect(context.controller).to be == :controller
		expect(context.localization).to be == :localization
		expect(context.request).to be == :request
		expect(context.response).to be_equal(document)
		expect(context.attributes).to be_equal(state.attributes)
		expect(context[:local]).to be == "Local"
		expect(context[:global]).to be == "Global"
		expect(context.current).to be_equal(state)
		expect(context.content).to be == :content
		expect(context.parent).to be == :parent
		expect(context.first).to be == :first
		expect(context.links(".", locale: "en"){|link| link}).to be == :links
		expect(linked).to be == [[["."], {locale: "en"}]]
	end
end
