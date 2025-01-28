# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2017-2025, by Samuel Williams.

require "utopia/content/namespace"

describe Utopia::Content::Namespace do
	let(:tags) do
		Module.new.tap do |mod|
			mod.extend(Utopia::Content::Namespace)
			
			mod.tag("foo") do |document, state|
			end
		end
	end
	
	it "should freeze tags" do
		tags.freeze
		
		expect(tags).to be(:frozen?) 
		expect(tags.named).to be(:frozen?) 
	end
	
	it "should have named tag" do
		expect(tags.call("foo", nil)).not.to be_nil
	end
end
