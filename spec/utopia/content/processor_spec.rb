#!/usr/bin/env rspec

# Copyright, 2015, by Samuel G. D. Williams. <http://www.codeotaku.com>
# 
# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:
# 
# The above copyright notice and this permission notice shall be included in
# all copies or substantial portions of the Software.
# 
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
# THE SOFTWARE.

require 'utopia/content/link'

module Utopia::Content::ProcessorSpec
	class TestDelegate
		def initialize
			@events = []
		end
		
		attr :events
		
		def method_missing(*args)
			@events << args
		end
	end
	
	describe Utopia::Content::Processor do
		it "should format open tags correctly" do
			foo_tag = Utopia::Content::Tag.new("foo", bar: nil, baz: 'bob')
			
			expect(foo_tag[:bar]).to be nil
			expect(foo_tag[:baz]).to be == 'bob'
			
			expect(foo_tag.to_s('content')).to be == '<foo bar baz="bob">content</foo>'
		end
		
		it "should parse single tag" do
			delegate = TestDelegate.new
			processor = Utopia::Content::Processor.new(delegate)
			
			processor.parse %Q{<foo></foo>}
			
			foo_tag = Utopia::Content::Tag.new("foo")
			expected_events = [
				[:tag_begin, foo_tag],
				[:tag_end, foo_tag],
			]
			
			expect(delegate.events).to be == expected_events
			
			expect(foo_tag.to_s)
		end
		
		it "should parse and escape text" do
			delegate = TestDelegate.new
			processor = Utopia::Content::Processor.new(delegate)
			
			processor.parse %Q{<foo>Bob &amp; Barley<!-- Comment --><![CDATA[Hello & World]]></foo>}
			
			foo_tag = Utopia::Content::Tag.new("foo")
			expected_events = [
				[:tag_begin, foo_tag],
				[:cdata, "Bob &amp; Barley"],
				[:cdata, "<!-- Comment -->"],
				[:cdata, "<![CDATA[Hello & World]]>"],
				[:tag_end, foo_tag],
			]
			
			expect(delegate.events).to be == expected_events
		end
		
		it "should fail with incorrect closing tag" do
			delegate = TestDelegate.new
			processor = Utopia::Content::Processor.new(delegate)
			
			expect{processor.parse %Q{<p>Foobar</dl>}}.to raise_exception(Utopia::Content::Processor::UnbalancedTagError)
		end
		
		it "should fail with unclosed tag" do
			delegate = TestDelegate.new
			processor = Utopia::Content::Processor.new(delegate)
			
			expect{processor.parse %Q{<p>Foobar}}.to raise_exception(Utopia::Content::Processor::UnbalancedTagError)
		end
	end
end
