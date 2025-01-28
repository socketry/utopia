# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2015-2025, by Samuel Williams.

require "utopia/middleware"

describe Utopia do
	it "should give a default path relative to the cwd" do
		expect(File).to be(:exist?, Utopia.default_root(".content", __dir__))
	end
end
