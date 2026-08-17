# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2026, by Samuel Williams.

require "utopia/response"

describe Utopia::Response do
	it "builds protocol responses" do
		response = subject[200, {"content-type" => "text/plain"}, ["Hello"]]
		
		expect(response).to be_a(Protocol::HTTP::Response)
		expect(response.status).to be == 200
	end
	
	it "builds redirects" do
		response = subject.redirect("/target")
		
		expect(response.status).to be == 302
		expect(response.headers["location"]).to be == "/target"
	end
	
	it "builds HTML responses" do
		response = subject.html("<h1>Hello</h1>", 201)
		
		expect(response.status).to be == 201
		expect(response.headers["content-type"]).to be == "text/html; charset=utf-8"
		expect(response.read).to be == "<h1>Hello</h1>"
	end
	
	it "passes through protocol responses" do
		response = Protocol::HTTP::Response[204]
		
		expect(subject.wrap(response)).to be_equal(response)
	end
	
	it "rejects unsupported responses" do
		expect{subject.wrap(Object.new)}.to raise_exception(TypeError)
	end
	
	it "rejects invalid converted responses" do
		response = Object.new
		def response.to_response = nil
		
		expect{subject.wrap(response)}.to raise_exception(TypeError)
	end
end
