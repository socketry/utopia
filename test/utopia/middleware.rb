# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2015-2026, by Samuel Williams.

require "utopia/middleware"

describe Utopia do
	it "should give a default path relative to the cwd" do
		expect(File).to be(:exist?, Utopia.default_root(".content", __dir__))
	end
	
	it "constructs the default application path" do
		path = Utopia.default_path(".content", __dir__)
		
		expect(path).to be == Utopia::Path[Utopia.default_root(".content", __dir__)]
	end
end
