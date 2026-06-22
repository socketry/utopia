# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2026, by Samuel Williams.

require "protocol/http/request"
require "utopia/request"

describe Utopia::Request do
	let(:http_request) {Protocol::HTTP::Request["POST", "/search?q=utopia"]}
	let(:request) {subject.new(http_request)}
	
	it "exposes the underlying protocol request" do
		expect(request.http).to be_equal(http_request)
		expect(request.method).to be == "POST"
		expect(request.path).to be == "/search?q=utopia"
		expect(request.path_info).to be == "/search"
		expect(request.query).to be == "q=utopia"
	end
	
	it "updates path info while preserving the query string" do
		request.path_info = "/find"
		
		expect(request.path).to be == "/find?q=utopia"
	end
	
	it "provides request-local attributes" do
		request.attributes[:locale] = "en"
		
		expect(request.attributes[:locale]).to be == "en"
	end
end
