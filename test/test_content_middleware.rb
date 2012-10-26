
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

