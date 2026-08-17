# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2026, by Samuel Williams.

require "utopia/content"

describe Utopia::Content::Middleware do
	let(:root) {File.expand_path("relative", __dir__)}
	let(:content) {Utopia::Content.new(Protocol::HTTP::Middleware::NotFound, root: root)}
	
	it "resolves relative tags from the logical invocation path" do
		node = content.lookup_node(Utopia::Path["/nested/index"])
		markup = node.process!(nil).read.gsub(/>\s+</, "><").strip
		
		expect(markup).to be == "<nested><physical>Hello World</physical></nested>"
	end
	
	it "falls back through the logical content hierarchy" do
		node = content.lookup_node(Utopia::Path["/fallback/index"])
		markup = node.process!(nil).read.gsub(/>\s+</, "><").strip
		
		expect(markup).to be == "<root><physical>Hello World</physical></root>"
	end
	
	it "resolves nested content paths through the physical hierarchy" do
		parent = content.lookup_node(Utopia::Path["/fallback/index"])
		node = content.lookup_tag("content:shared/frame", parent)
		
		expect(node.uri_path).to be == Utopia::Path["/shared/frame"]
		expect(node.request_path).to be == Utopia::Path["/fallback/shared/frame"]
		expect(node.process!(nil).read).to be == "Nested Frame\n"
	end
	
	it "returns nil when nested content does not exist" do
		parent = content.lookup_node(Utopia::Path["/fallback/index"])
		
		expect(content.lookup_tag("content:missing/absent", parent)).to be_nil
	end
	
	it "avoids resolving the current name recursively" do
		parent = content.lookup_node(Utopia::Path["/fallback/index"])
		node = content.lookup_tag("content:fallback", parent)
		
		expect(node.uri_path).to be == Utopia::Path["/fallback"]
		expect(node.process!(nil).read).to be == "Fallback\n"
	end
end
