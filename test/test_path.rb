
require 'test/unit'
require 'utopia/path'

class TestPath < Test::Unit::TestCase
	def test_absolute_path_concatenation
		root = Utopia::Path["/"]
		
		assert root.absolute?
		assert_equal Utopia::Path["/foo/bar"], (root + Utopia::Path["foo/bar"])
	end
end

