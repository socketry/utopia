# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2015-2020, by Samuel Williams.

require 'utopia/content'

RSpec.describe Utopia::Content::Node do
	let(:root) {File.expand_path("node", __dir__)}
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
	
	it "should list related links" do
		node = content.lookup_node(Utopia::Path['/related/foo'], 'en')
		
		links = node.related_links
		
		expect(links.size).to be == 2
		expect(links[0].name).to be == 'foo'
		expect(links[0].locale).to be == 'en'
		
		expect(links[1].name).to be == 'foo'
		expect(links[1].locale).to be == 'ja'
	end
	
	it "should look up node by path" do
		node = content.lookup_node(Utopia::Path['/lookup/index'])
		
		expect(node.process!(nil)).to be == [200, {"content-type"=>"text/html; charset=utf-8"}, ["<p>Hello World</p>"]]
	end
	
	describe '#local_path' do
		let(:base) {Pathname.new(root)}
		
		it "can compute relative path from index node" do
			node = content.lookup_node(Utopia::Path['/ordered/index'])
			
			expect(node.local_path("preview.jpg")).to eq(base + 'ordered/preview.jpg')
		end
		
		it "can compute relative path from named node" do
			node = content.lookup_node(Utopia::Path['/ordered/first'])
			
			expect(node.local_path("preview.jpg")).to eq(base + 'ordered/preview.jpg')
		end
	end
	
	describe '#relative_path' do
		it "can compute relative path from index node" do
			node = content.lookup_node(Utopia::Path['/ordered/index'])
			
			expect(node.relative_path("preview.jpg")).to eq(Utopia::Path['/ordered/preview.jpg'])
		end
		
		it "can compute relative path from named node" do
			node = content.lookup_node(Utopia::Path['/ordered/first'])
			
			expect(node.relative_path("preview.jpg")).to eq(Utopia::Path['/ordered/preview.jpg'])
		end
	end
end
