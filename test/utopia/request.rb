# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2026, by Samuel Williams.

require "protocol/http/request"
require "utopia/request"

describe Utopia::Request do
	let(:request) {subject["POST", "/search?q=utopia&tag=ruby&tag=async", {"cookie" => "a=1; b=2"}]}
	
	it "proxies a protocol HTTP request" do
		expect(request.delegate).to be_a(Protocol::HTTP::Request)
		expect(request.headers).to be_equal(request.delegate.headers)
		expect(request.to_s).to be == request.delegate.to_s
		expect(request).to be(:respond_to?, :headers)
		expect(request).to be(:respond_to?, :scheme=)
	end
	
	it "duplicates the underlying protocol request" do
		copy = request.dup
		copy.path = "/copy"
		
		expect(copy.delegate).not.to be_equal(request.delegate)
		expect(copy.path).to be == "/copy"
		expect(request.path).to be == "/search?q=utopia&tag=ruby&tag=async"
	end
	
	it "does not proxy unknown methods" do
		expect(request).not.to be(:respond_to?, :unknown_request_method)
		expect{request.unknown_request_method}.to raise_exception(NoMethodError)
	end
	
	it "provides ambient request state" do
		previous_request = subject.current
		
		begin
			subject.current = request
			
			expect(subject.current).to be_equal(request)
			expect(subject.current!).to be_equal(request)
		ensure
			subject.current = previous_request
		end
	end
	
	it "inherits ambient request state into nested fibers" do
		previous_request = subject.current
		
		begin
			subject.current = request
			
			fiber = Fiber.new do
				subject.current
			end
			
			expect(fiber.resume).to be_equal(request)
		ensure
			subject.current = previous_request
		end
	end
	
	it "provides path information" do
		expect(request.path_info).to be == "/search"
		expect(request.query).to be == "q=utopia&tag=ruby&tag=async"
	end
	
	it "updates path information while preserving query string" do
		request.path_info = "/find"
		
		expect(request.path).to be == "/find?q=utopia&tag=ruby&tag=async"
		expect(request.path_info).to be == "/find"
		expect(request.request_path).to be == "/search"
	end
	
	it "provides HTTP method predicates" do
		expect(request.request_method).to be == "POST"
		expect(request.post?).to be == true
		expect(request.get?).to be == false
		expect(request.options?).to be == false
		
		request.method = "GET"
		expect(request.get?).to be == true
	end
	
	it "provides decoded query arguments" do
		expect(request.arguments).to be == {
			"q" => "utopia",
			"tag" => ["ruby", "async"]
		}
	end
	
	it "does not expose ambiguous Rack request accessors" do
		expect(request).not.to be(:respond_to?, :params)
		expect(request).not.to be(:respond_to?, :[])
	end
	
	it "provides decoded cookies" do
		expect(request.cookies).to be == {"a" => "1", "b" => "2"}
	end
	
	it "has no session by default" do
		expect(request.session).to be_nil
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
		session = Object.new
		request.session = session
		
		derived = request.with(method: "GET", path_info: "/find")
		
		expect(derived).not.to be_equal(request)
		expect(derived.method).to be == "GET"
		expect(derived.path).to be == "/find?q=utopia&tag=ruby&tag=async"
		expect(derived.request_path).to be == "/search"
		expect(derived.delegate).not.to be_equal(request.delegate)
		expect(derived.session).to be_equal(session)
	end
	
	it "preserves the original request path across multiple derived requests" do
		derived = request.with(path_info: "/find")
		derived = derived.with(path_info: "/lookup")
		
		expect(derived.path_info).to be == "/lookup"
		expect(derived.request_path).to be == "/search"
	end
end
