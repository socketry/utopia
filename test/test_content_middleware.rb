# Copyright, 2012, by Samuel G. D. Williams. <http://www.codeotaku.com>
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

require 'test/unit'
require 'rack/mock'
require 'utopia/middleware/content'

class TestContentMiddleware < Test::Unit::TestCase
	APP = lambda {|env| [404, [], []]}
	
	class TestDelegate
		def initialize
			@events = []
		end
		
		attr :events
		
		def method_missing(*args)
			@events << args
		end
	end
	
	def test_processor_events_single_tag
		delegate = TestDelegate.new
		processor = Utopia::Middleware::Content::Processor.new(delegate)
		
		processor.parse %Q{<foo></foo>}
		
		foo_tag = Utopia::Tag.new("foo")
		expected_events = [
			[:tag_begin, foo_tag],
			[:tag_end, foo_tag],
		]
		
		assert_equal expected_events, delegate.events
	end
	
	def test_processor_events_text
		delegate = TestDelegate.new
		processor = Utopia::Middleware::Content::Processor.new(delegate)
		
		processor.parse %Q{<foo>Bob &amp; Barley<!-- Comment --><![CDATA[Hello & World]]></foo>}
		
		foo_tag = Utopia::Tag.new("foo")
		expected_events = [
			[:tag_begin, foo_tag],
			[:cdata, "Bob &amp; Barley"],
			[:cdata, "<!-- Comment -->"],
			[:cdata, "Hello &amp; World"],
			[:tag_end, foo_tag],
		]
		
		assert_equal expected_events, delegate.events
	end
	
	def test_content_xnode
		root = File.expand_path("../content_root", __FILE__)
		content = Utopia::Middleware::Content.new(APP, :root => root)
		
		path = Utopia::Path.create('/index')
		node = content.lookup_node(path)
		assert_equal Utopia::Middleware::Content::Node, node.class
		
		output = StringIO.new
		node.process!({}, output, {})
		assert_equal %Q{<h1>Hello World</h1>}, output.string
	end
end

