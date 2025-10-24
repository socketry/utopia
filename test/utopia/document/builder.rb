# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2025, by Samuel Williams.

require 'utopia/content/builder'
require 'utopia/content/tags'
require 'xrb/builder'

describe Utopia::Content::Builder do
	it "should inherit from XRB::Builder" do
		expect(Utopia::Content::Builder.superclass).to be == XRB::Builder
	end
	
	it "should accept positional arguments" do
		builder = Utopia::Content::Builder.new(nil, nil, nil, {})
		
		expect(builder.parent).to be_nil
		expect(builder.tag).to be_nil
		expect(builder.node).to be_nil
		expect(builder.attributes).to be == {}
	end
	
	it "should default attributes to tag.to_hash" do
		tag = XRB::Tag.new('div', false, {'id' => 'test'})
		
		builder = Utopia::Content::Builder.new(nil, tag, nil)
		
		expect(builder.attributes).to be == {'id' => 'test'}
	end
	
	it "should support fragment rendering via build_markup protocol" do
		builder = Utopia::Content::Builder.new(nil, nil, nil, {})
		
		fragment = XRB::Builder.fragment do |builder|
			builder.inline('p') do
				builder.text "Hello from fragment"
			end
		end
		
		builder.text(fragment)
		
		expect(builder.output).to be =~ /Hello from fragment/
		expect(builder.output).not.to be =~ /&lt;/
	end
	
	it "should track parent builders" do
		parent = Utopia::Content::Builder.new(nil, nil, nil, {})
		child = Utopia::Content::Builder.new(parent, nil, nil, {})
		
		expect(child.parent).to be == parent
	end
	
	it "should track tags" do
		builder = Utopia::Content::Builder.new(nil, nil, nil, {})
		
		expect(builder.tags).to be == []
		expect(builder).to be(:empty?)
		
		tag = XRB::Tag.new('div', false, {})
		builder.tag_begin(tag)
		
		expect(builder.tags).to be == [tag]
		expect(builder).not.to be(:empty?)
	end
	
	it "should support deferred content" do
		builder = Utopia::Content::Builder.new(nil, nil, nil, {})
		
		expect(builder.deferred).to be == []
		
		deferred_tag = builder.defer { "deferred content" }
		
		expect(builder.deferred.size).to be == 1
		expect(deferred_tag.name).to be == "utopia:deferred"
		expect(deferred_tag.attributes[:id]).to be == 0
	end
	
	it "should write text content" do
		builder = Utopia::Content::Builder.new(nil, nil, nil, {})
		
		builder.write("Hello ")
		builder.write("World")
		
		expect(builder.output).to be == "Hello World"
	end
	
	it "should escape regular text via text method" do
		builder = Utopia::Content::Builder.new(nil, nil, nil, {})
		
		builder.text("<script>alert('xss')</script>")
		
		expect(builder.output).to be =~ /&lt;script&gt;/
		expect(builder.output).not.to be =~ /<script>/
	end
	
	it "should not escape objects with build_markup protocol" do
		builder = Utopia::Content::Builder.new(nil, nil, nil, {})
		
		# Use XRB::Builder.fragment which implements build_markup
		fragment = XRB::Builder.fragment do |b|
			b.inline('p') { b.text "Safe HTML" }
		end
		
		builder.text(fragment)
		
		expect(builder.output).to be =~ /<p>Safe HTML<\/p>/
	end
end
