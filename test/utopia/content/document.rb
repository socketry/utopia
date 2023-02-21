# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2017-2023, by Samuel Williams.

require 'utopia/content/document'

describe Utopia::Content::Document do
	let(:document) {subject.new(nil, {})}
	
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
			div = Utopia::Content::Tag.opened('div')
			span = Utopia::Content::Tag.opened('span')
			document.tag_begin(div)
			document.tag_end(span)
		end
		
		expect{document.render_node(node)}.to raise_exception(Utopia::Content::UnbalancedTagError, message: be =~ /tag span/)
	end
end
