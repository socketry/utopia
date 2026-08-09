# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2016-2026, by Samuel Williams.

require "utopia/http"

describe Utopia::HTTP::Status.new(:found) do
	it "should load symbolic status" do
		expect(subject.to_i).to be == 302
	end
	
	it "gives a status string" do
		expect(subject.to_s).to be == "Found"
	end
	
end

describe Utopia::HTTP::Status do
	it "provides descriptions for standard status codes" do
		expect(Utopia::HTTP::Status.new(103).to_s).to be == "Early Hints"
		expect(Utopia::HTTP::Status.new(418).to_s).to be == "I'm a Teapot"
		expect(Utopia::HTTP::Status.new(429).to_s).to be == "Too Many Requests"
		expect(Utopia::HTTP::Status.new(502).to_s).to be == "Bad Gateway"
	end
	
	it "uses the numeric code when no description exists" do
		expect(Utopia::HTTP::Status.new(444).to_s).to be == "444"
	end
	
	it "should fail when given invalid code" do
		expect{Utopia::HTTP::Status.new(1000)}.to raise_exception(ArgumentError)
	end
end
