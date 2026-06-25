# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2026, by Samuel Williams.

require "protocol/http/request"
require "utopia/request"

describe Protocol::HTTP::Request do
	let(:request) {subject["POST", "/search?q=utopia&tag=ruby&tag=async", {"cookie" => "a=1; b=2"}]}
	
	it "provides path information" do
		expect(request.path_info).to be == "/search"
		expect(request.query).to be == "q=utopia&tag=ruby&tag=async"
	end
	
	it "updates path information while preserving query string" do
		request.path_info = "/find"
		
		expect(request.path).to be == "/find?q=utopia&tag=ruby&tag=async"
		expect(request.path_info).to be == "/find"
	end
	
	it "provides HTTP method predicates" do
		expect(request.request_method).to be == "POST"
		expect(request.post?).to be == true
		expect(request.get?).to be == false
		expect(request.options?).to be == false
	end
	
	it "provides decoded query arguments" do
		expect(request.arguments).to be == {
			"q" => "utopia",
			"tag" => ["ruby", "async"]
		}
		
		expect(request["q"]).to be == "utopia"
		expect(request[:q]).to be == "utopia"
	end
	
	it "provides decoded cookies" do
		expect(request.cookies).to be == {"a" => "1", "b" => "2"}
	end
	
	it "provides common request conveniences" do
		request.scheme = "https"
		request.authority = "example.com"
		request.headers["referer"] = "/from"
		
		expect(request.scheme).to be == "https"
		expect(request.ssl?).to be == true
		expect(request.host_with_port).to be == "example.com"
		expect(request.base_url).to be == "https://example.com"
		expect(request.url).to be == "https://example.com/search?q=utopia&tag=ruby&tag=async"
		expect(request.referer).to be == "/from"
		expect(request.referrer).to be == "/from"
	end
	
	it "builds derived requests" do
		derived = request.with(method: "GET", path_info: "/find")
		
		expect(derived).not.to be_equal(request)
		expect(derived.method).to be == "GET"
		expect(derived.path).to be == "/find?q=utopia&tag=ruby&tag=async"
	end
end
