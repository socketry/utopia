# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2016-2025, by Samuel Williams.

require "utopia/http"

describe Utopia::HTTP::Status.new(:found) do
	it "should load symbolic status" do
		expect(subject.to_i).to be == 302
	end
	
	it "gives a status string" do
		expect(subject.to_s).to be == "Found"
	end
	
	it "can be used as a response body" do
		body = subject.to_enum(:each).next
		expect(body).to be == "Found"
	end
end

describe Utopia::HTTP::Status do
	it "provides descriptions for standard status codes" do
		expect(Utopia::HTTP::Status.new(103).to_s).to be == "Early Hints"
		expect(Utopia::HTTP::Status.new(418).to_s).to be == "I'm a Teapot"
		expect(Utopia::HTTP::Status.new(429).to_s).to be == "Too Many Requests"
		expect(Utopia::HTTP::Status.new(502).to_s).to be == "Bad Gateway"
	end
	
	it "should fail when given invalid code" do
		expect{Utopia::HTTP::Status.new(1000)}.to raise_exception(ArgumentError)
	end
end
