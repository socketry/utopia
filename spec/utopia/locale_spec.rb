#!/usr/bin/env rspec
# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2015-2020, by Samuel Williams.

require 'utopia/locale'

RSpec.shared_examples Utopia::Locale do |input|
	it "should load locale #{input.inspect}" do
		expect(Utopia::Locale.load(input)).to be_kind_of(Utopia::Locale)
	end
end

RSpec.describe Utopia::Locale do
	it_behaves_like Utopia::Locale, 'en-US'
	it_behaves_like Utopia::Locale, ['en', 'US']
	it_behaves_like Utopia::Locale, Utopia::Locale.load('en-US')
	
	it "should load from string" do
		locale = Utopia::Locale.load('en-US')
		
		expect(locale.language).to be == 'en'
		expect(locale.country).to be == 'US'
		expect(locale.variant).to be == nil
	end
	
	it "should load from nil and return nil" do
		expect(Utopia::Locale.load(nil)).to be == nil
	end
	
	it "should dump nil and give nil" do
		expect(Utopia::Locale.dump(nil)).to be == nil
	end
	
	it "should dump locale and give string" do
		locale = Utopia::Locale.new('en', 'US')
		
		expect(Utopia::Locale.dump(locale)).to be == 'en-US'
	end
end
