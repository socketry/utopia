# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2017-2022, by Samuel Williams.

require 'utopia/content/document'

RSpec.describe Utopia::Content::Document do
	subject{described_class.new(nil, {})}
	
	it "should generate valid self-closing markup" do
		node = proc do |document, state|
			subject.tag("img", src: "cats.jpg")
		end
		
		result = subject.render_node(node)
		
		expect(result).to be == '<img src="cats.jpg"/>'
	end
	
	it "should generate valid nested markup" do
		node = proc do |document, state|
			subject.tag("div") do
				subject.tag("img", src: "cats.jpg")
			end
		end
		
		result = subject.render_node(node)
		
		expect(result).to be == '<div><img src="cats.jpg"/></div>'
	end
	
	it "should fail if tags are unbalanced" do
		node = proc do |document, state|
			div = Utopia::Content::Tag.opened('div')
			span = Utopia::Content::Tag.opened('span')
			subject.tag_begin(div)
			subject.tag_end(span)
		end
		
		expect{subject.render_node(node)}.to raise_error Utopia::Content::UnbalancedTagError, /tag span/
	end
end
