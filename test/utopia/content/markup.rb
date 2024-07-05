# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2015-2024, by Samuel Williams.

require 'utopia/content/markup'

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
	it "should format open tags correctly" do
		foo_tag = Utopia::Content::Tag.opened("foo", bar: true, baz: 'bob')
		
		expect(foo_tag[:bar]).to be == true
		expect(foo_tag[:baz]).to be == 'bob'
		
		expect(foo_tag.to_s('content')).to be == '<foo bar baz="bob">content</foo>'
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
	
	it "should fail with incorrect closing tag" do
		expect{parse %Q{<p>Foobar</dl>}}.to raise_exception(Utopia::Content::MarkupParser::UnbalancedTagError)
	end
	
	it "should fail with unclosed tag" do
		expect{parse %Q{<p>Foobar}}.to raise_exception(Utopia::Content::MarkupParser::UnbalancedTagError)
	end
end
