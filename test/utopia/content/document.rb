# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2017-2025, by Samuel Williams.

require "utopia/content/document"
require "rack/request"

describe Utopia::Content::Document do
	let(:env) {Hash["REQUEST_PATH" => "/index"]}
	let(:request) {Rack::Request.new(env)}
	let(:document) {subject.new(request, {})}
	
	it "should generate valid self-closing markup" do
		node = proc do |document, state|
			document.tag("img", src: "cats.jpg")
		end
		
		result = document.render_node(node)
		
		expect(result).to be == '<img src="cats.jpg"/>'
	end
	
	it "should generate valid nested markup" do
		node = proc do |document, state|
			document.tag("div") do
				document.tag("img", src: "cats.jpg")
			end
		end
		
		result = document.render_node(node)
		
		expect(result).to be == '<div><img src="cats.jpg"/></div>'
	end
	
	it "should fail if tags are unbalanced" do
		node = proc do |document, state|
			div = Utopia::Content::Tag.opened("div")
			span = Utopia::Content::Tag.opened("span")
			document.tag_begin(div)
			document.tag_end(span)
		end
		
		expect{document.render_node(node)}.to raise_exception(Utopia::Content::UnbalancedTagError, message: be =~ /tag span/)
	end
	
	it "generates an empty base uri" do
		relative_to = Utopia::Path["/page"]
		expect(document.base_uri(relative_to)).to be == Utopia::Path[""]
	end
	
	with "nested request path" do
		let(:env) {Hash["REQUEST_PATH" => "/nested/index"]}
		
		it "generates a relative base uri" do
			relative_to = Utopia::Path["/page"]
			expect(document.base_uri(relative_to)).to be == Utopia::Path[".."]
		end
	end
end
