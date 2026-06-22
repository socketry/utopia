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
	
	it "provides HTTP method predicates" do
		expect(request.request_method).to be == "POST"
		expect(request.post?).to be == true
		expect(request.get?).to be == false
		expect(request.options?).to be == false
	end
	
	it "looks up arguments by string or symbol keys" do
		expect(request["q"]).to be == "utopia"
		expect(request[:q]).to be == "utopia"
	end
	
	it "prefers request-local attributes over arguments" do
		request[:q] = "local"
		
		expect(request[:q]).to be == "local"
	end
	
	it "provides common request conveniences" do
		http_request.scheme = "https"
		http_request.authority = "example.com"
		http_request.headers["referer"] = "/from"
		
		request["utopia.session"] = {"user_id" => 10}
		
		expect(request.scheme).to be == "https"
		expect(request.ssl?).to be == true
		expect(request.host_with_port).to be == "example.com"
		expect(request.base_url).to be == "https://example.com"
		expect(request.url).to be == "https://example.com/search?q=utopia"
		expect(request.referer).to be == "/from"
		expect(request.referrer).to be == "/from"
		expect(request.session).to be == {"user_id" => 10}
	end
end
