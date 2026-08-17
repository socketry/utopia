# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2015-2025, by Samuel Williams.

require "utopia/path/matcher"

describe Utopia::Path::Matcher do
	it "should match strings" do
		path = Utopia::Path["users/20/edit"]
		matcher = Utopia::Path::Matcher[users: "users"]
		
		match_data = matcher.match(path)
		expect(match_data).not.to be_nil
		
		expect(match_data.post_match).to be == Utopia::Path["20/edit"]
	end
	
	it "shouldn't match strings" do
		path = Utopia::Path["users/20/edit"]
		matcher = Utopia::Path::Matcher[accounts: "accounts"]
		
		match_data = matcher.match(path)
		expect(match_data).to be_nil
	end
	
	it "shouldn't match integer" do
		path = Utopia::Path["users/20/edit"]
		matcher = Utopia::Path::Matcher[id: Integer]
		
		match_data = matcher.match(path)
		expect(match_data).to be_nil
	end
	
	it "should match regexps" do
		path = Utopia::Path["users/20/edit"]
		matcher = Utopia::Path::Matcher[users: /users/, id: Integer, action: String]
		
		match_data = matcher.match(path)
		expect(match_data).not.to be_falsey
		
		expect(match_data[:users].to_s).to be == "users"
		expect(match_data[:id]).to be == 20
		expect(match_data[:action]).to be == "edit"
	end
	
	it "coerces floating-point and custom components" do
		component = Struct.new(:value)
		path = Utopia::Path["1.5/example/raw"]
		matcher = subject[ratio: Float, component: component, raw: nil]
		
		match_data = matcher.match(path)
		
		expect(match_data[:ratio]).to be == 1.5
		expect(match_data[:component]).to have_attributes(value: be == "example")
		expect(match_data[:raw]).to be == "raw"
	end
end
