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
end
