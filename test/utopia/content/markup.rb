# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2015-2026, by Samuel Williams.

require "utopia/content/markup"

class TestDelegate
	def initialize
		@events = []
	end
	
	attr :events
	
	def method_missing(*arguments)
		@events << arguments
	end
end

describe Utopia::Content::MarkupParser do
	it "normalizes symbolic hash membership" do
		attributes = Utopia::Content::SymbolicHash.new
		attributes[:title] = "Hello"
		
		expect(attributes.fetch("title")).to be == "Hello"
		expect(attributes).to be(:include?, :title)
		expect(attributes).to be(:include?, "title")
	end
	
	it "describes parsed tags" do
		tag = subject::ParsedTag.new("section", 0)
		
		expect(tag.to_s).to be == "<section>"
		
		tag.tag.attributes[:class] = "content"
		expect(tag.to_s).to be == "<section ...>"
	end
	
	it "should format open tags correctly" do
		foo_tag = Utopia::Content::Tag.opened("foo", bar: true, baz: "bob")
		
		expect(foo_tag[:bar]).to be == true
		expect(foo_tag[:baz]).to be == "bob"
		
		expect(foo_tag.to_s("content")).to be == '<foo bar baz="bob">content</foo>'
	end
	
	def parse(string)
		delegate = TestDelegate.new
		
		buffer = XRB::Buffer.new(string)
		Utopia::Content::MarkupParser.new(buffer, delegate).parse!
		
		return delegate
	end
	
	it "should parse single tag" do
		delegate = parse %Q{<foo></foo>}
		
		foo_tag = Utopia::Content::Tag.opened("foo")
		expected_events = [
			[:tag_begin, foo_tag],
			[:tag_end, foo_tag],
		]
		
		expect(delegate.events).to be == expected_events
		
		expect(foo_tag.to_s)
	end
	
	it "should parse and escape text" do
		delegate = parse %Q{<foo>Bob &amp; Barley<!-- Comment --><![CDATA[Hello & World]]></foo>}
		
		foo_tag = Utopia::Content::Tag.opened("foo")
		expected_events = [
			[:tag_begin, foo_tag],
			[:text, "Bob & Barley"],
			[:write, "<!-- Comment -->"],
			[:write, "Hello & World"],
			[:tag_end, foo_tag],
		]
		
		expect(delegate.events).to be == expected_events
	end
	
	it "should parse processing instructions" do
		delegate = TestDelegate.new
		parser = subject.new(XRB::Buffer.new(""), delegate)
		
		parser.instruction("<?example?>")
		
		expect(delegate.events).to be == [[:write, "<?example?>"]]
	end
	
	it "should fail with incorrect closing tag" do
		error = begin
			parse %Q{<p>Foobar</dl>}
		rescue subject::UnbalancedTagError => error
			error
		end
		
		expect(error).to be_a(subject::UnbalancedTagError)
		expect(error.start_location.to_s).to be == "[1:1]"
		expect(error.end_location.to_s).to be == "[1:11]"
		expect(error.to_s).to be =~ /<p> was closed by <dl>/
	end
	
	it "should fail with unclosed tag" do
		error = begin
			parse %Q{<p>Foobar}
		rescue subject::UnbalancedTagError => error
			error
		end
		
		expect(error).to be_a(subject::UnbalancedTagError)
		expect(error.end_location).to be_nil
		expect(error.to_s).to be =~ /<p> was not closed/
	end
end
