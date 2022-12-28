# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2015-2022, by Samuel Williams.

require 'utopia/middleware'

module Utopia::MiddlewareSpec
	describe Utopia do
		it "should give a default path relative to the cwd" do
			expect(File).to exist(Utopia::default_root('content_spec', File.dirname(__FILE__)))
		end
	end
end
