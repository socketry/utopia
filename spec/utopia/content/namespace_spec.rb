# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2017-2022, by Samuel Williams.

require 'utopia/content/namespace'

RSpec.describe Utopia::Content::Namespace do
	let(:tags) do
		Module.new.tap do |mod|
			mod.extend(Utopia::Content::Namespace)
			
			mod.tag('foo') do |document, state|
			end
		end
	end
	
	it "should freeze tags" do
		tags.freeze
		
		expect(tags).to be_frozen
		expect(tags.named).to be_frozen
	end
	
	it "should have named tag" do
		expect(tags.call('foo', nil)).to_not be_nil
	end
end
