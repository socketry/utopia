# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2017-2026, by Samuel Williams.

require "utopia/content/document"
require "utopia/request"

describe Utopia::Content::Document do
	let(:path) {"/index"}
	let(:request) {Utopia::Request["GET", path]}
	let(:document) {subject.new(request, {})}
	
	it "retains the application request" do
		expect(document.request).to be == request
		expect(document.request.delegate).to be == request.delegate
	end
	
	it "exposes document attributes and request context" do
		variables = Object.new
		localization = Object.new
		request.variables = variables
		document = subject.new(request, {title: "Hello"}, localization: localization)
		
		expect(document[:title]).to be == "Hello"
		expect(document.controller).to be_equal(variables)
		expect(document.localization).to be_equal(localization)
	end
	
	it "uses the original request path" do
		request.path = "/rewritten"
		
		expect(document.request_path).to be == Utopia::Path["/index"]
	end
	
	it "uses the normalized original request path" do
		request = Utopia::Request["GET", "/nested/../%69ndex"]
		document = subject.new(request, {})
		
		request.path = "/rewritten"
		
		expect(document.request_path).to be == Utopia::Path["/index"]
	end
	
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
	
	it "generates a base uri from the current node" do
		node = Struct.new(:uri_path) do
			def call(document, state)
				document.text(document.base_uri.to_s)
			end
		end.new(Utopia::Path["/page"])
		
		expect(document.render_node(node)).to be == ""
	end
	
	it "exposes captured content while rendering" do
		node = proc do |document, state|
			document.text(document.content)
		end
		
		expect(document.render_node(node)).to be == ""
	end
	
	with "nested request path" do
		let(:path) {"/nested/index"}
		
		it "generates a relative base uri" do
			relative_to = Utopia::Path["/page"]
			expect(document.base_uri(relative_to)).to be == Utopia::Path[".."]
		end
	end
end
