# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2026, by Samuel Williams.

require "utopia/content/builder"

describe Utopia::Content::Builder do
	it "parses captured content for non-callable nodes" do
		builder = subject.new(nil, nil, Object.new, {})
		markup = nil
		document = Object.new
		document.define_singleton_method(:parse_markup) do |content|
			markup = content
		end
		
		builder.write("<p>Hello</p>")
		builder.call(document)
		
		expect(markup).to be == "<p>Hello</p>"
	end
	
	it "escapes plain text" do
		builder = subject.new(nil, nil, Object.new, {})
		content = Object.new
		content.define_singleton_method(:to_s){"Cats & Dogs"}
		
		builder.text(content)
		
		expect(builder.to_s).to be == "Cats &amp; Dogs"
	end
end
