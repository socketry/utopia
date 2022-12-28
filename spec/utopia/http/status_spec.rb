# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2016-2022, by Samuel Williams.

require 'utopia/http'

RSpec.describe Utopia::HTTP::Status.new(:found) do
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

RSpec.describe Utopia::HTTP::Status do
	it "should fail when given invalid code" do
		expect{Utopia::HTTP::Status.new(1000)}.to raise_error(ArgumentError)
	end
end
