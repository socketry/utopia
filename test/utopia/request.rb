# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2026, by Samuel Williams.

require "protocol/http/request"
require "utopia/request"
require "utopia/path"

describe Utopia::Request do
	let(:request) {subject["POST", "/search?q=utopia&tag[]=ruby&tag[]=async", {"cookie" => "a=1; b=2"}]}
	
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
		expect(request.path).to be == "/search?q=utopia&tag[]=ruby&tag[]=async"
	end
	
	it "does not proxy unknown methods" do
		expect(request).not.to be(:respond_to?, :unknown_request_method)
		expect{request.unknown_request_method}.to raise_exception(NoMethodError)
	end
	
	it "provides a structured URL" do
		expect(request.url).to be_a(Protocol::URL::Relative)
		expect(request.url.path).to be == Protocol::URL::Path["/search"]
		expect(request.url.query).to be == "q=utopia&tag[]=ruby&tag[]=async"
		expect(request.query).to be == "q=utopia&tag[]=ruby&tag[]=async"
	end
	
	it "normalizes the external path while preserving the query" do
		request = subject["GET", "//users/./samuel/../amy?redirect=/a//b&value=%2e%2e"]
		
		expect(request.path).to be == "//users/./samuel/../amy?redirect=/a//b&value=%2e%2e"
		expect(request.url.path).to be == Protocol::URL::Path["/users/amy"]
		expect(request.url.query).to be == "redirect=/a//b&value=%2e%2e"
		expect(request.query).to be == "redirect=/a//b&value=%2e%2e"
		expect(request.request_path).to be == Protocol::URL::Path["//users/./samuel/../amy"]
	end
	
	it "keeps encoded path delimiters separate from the query" do
		request = subject["GET", "/search%3farchive?query=%"]
		
		expect(request.url.path).to be == Protocol::URL::Path["/search%3farchive"]
		expect(request.query).to be == "query=%"
	end
	
	it "does not decode external paths more than once" do
		request = subject["GET", "/%252e%252e/value"]
		
		expect(request.url.path).to be == Protocol::URL::Path["/%252e%252e/value"]
		expect(Utopia::Path.create(request.url.path).components).to be == ["", "%2e%2e", "value"]
	end
	
	it "clamps parent components at the root" do
		request = subject["GET", "/../../../foo"]
		
		expect(request.url.path).to be == Protocol::URL::Path["/foo"]
	end
	
	it "rejects malformed or ambiguous external paths as bad requests" do
		[
			"relative/path",
			"/invalid%2",
			"/fragment#value",
			"/control\0value",
			"/control%00value",
			"/ambiguous\\value",
			"/ambiguous%5Cvalue",
		].each do |path|
			expect do
				subject["GET", path]
			end.to raise_exception(Utopia::InvalidPathError) do |error|
				expect(error).to be_a(Protocol::HTTP::BadRequest)
			end
		end
	end
	
	it "preserves encoded path separators as component data" do
		request = subject["GET", "/files/a%2Fb"]
		
		expect(request.url.path.encoded).to be == "/files/a%2Fb"
		expect(request.url.path.components).to be == ["", "files", "a/b"]
		expect(Utopia::Path[request.url.path].components).to be == ["", "files", "a/b"]
	end
	
	it "supports the server-wide OPTIONS target" do
		request = subject["OPTIONS", "*"]
		
		expect(request.url.path).to be == Protocol::URL::Path["*"]
	end
	
	it "updates the URL while preserving its query string" do
		request.url = request.url.with(path: "/find")
		
		expect(request.path).to be == "/find?q=utopia&tag[]=ruby&tag[]=async"
		expect(request.url.path).to be == Protocol::URL::Path["/find"]
		expect(request.request_path).to be == Protocol::URL::Path["/search"]
	end
	
	it "does not normalize trusted internal request target assignments" do
		request.path = "/internal/../target"
		
		expect(request.url.path).to be == Protocol::URL::Path["/internal/../target"]
	end
	
	it "identifies POST requests" do
		expect(request.post?).to be == true
		
		request.method = "GET"
		expect(request.post?).to be == false
	end
	
	it "provides decoded query arguments" do
		expect(request.query_arguments).to be == {
			"q" => "utopia",
			"tag" => ["ruby", "async"]
		}
	end
	
	it "provides nested query arguments" do
		request.path = "/search?user[name]=Samuel&query=hello+world"
		
		expect(request.query_arguments).to be == {
			"user" => {"name" => "Samuel"},
			"query" => "hello world"
		}
	end
	
	it "distinguishes absent and empty query values" do
		request.path = "/search?absent&empty="
		
		expect(request.query_arguments).to be == {"absent" => nil, "empty" => ""}
	end
	
	it "does not expose ambiguous Rack request accessors" do
		expect(request).not.to be(:respond_to?, :params)
		expect(request).not.to be(:respond_to?, :[])
		expect(request).not.to be(:respond_to?, :arguments)
		expect(request).not.to be(:respond_to?, :form_arguments)
		expect(request).not.to be(:respond_to?, :parsed_body)
	end
	
	it "provides decoded cookies" do
		expect(request.cookies).to be == {"a" => "1", "b" => "2"}
	end
	
	it "preserves cookie values without applying form decoding" do
		request.headers["cookie"] = "plus=a+b; encoded=%2F"
		
		expect(request.cookies).to be == {"plus" => "a+b", "encoded" => "%2F"}
	end
	
	it "has no application state by default" do
		expect(request.session).to be_nil
		expect(request.variables).to be_nil
		expect(request.localization).to be_nil
		expect(request.exception).to be_nil
	end
	
	it "provides request metadata" do
		request.scheme = "https"
		request.authority = "example.com"
		request.headers["referer"] = "/from"
		
		expect(request.scheme).to be == "https"
		expect(request.host).to be == "example.com"
		expect(request.url).to be_a(Protocol::URL::Absolute)
		expect(request.url.to_s).to be == "https://example.com/search?q=utopia&tag[]=ruby&tag[]=async"
		expect(request.referrer).to be == "/from"
	end
	
	it "builds derived requests" do
		session = Object.new
		variables = Object.new
		localization = Object.new
		request.session = session
		request.variables = variables
		request.localization = localization
		exception = StandardError.new("Boom")
		request.exception = exception
		
		derived = request.with(method: "GET", url: request.url.with(path: "/find"))
		
		expect(derived).not.to be_equal(request)
		expect(derived.method).to be == "GET"
		expect(derived.path).to be == "/find?q=utopia&tag[]=ruby&tag[]=async"
		expect(derived.request_path).to be == Protocol::URL::Path["/search"]
		expect(derived.delegate).not.to be_equal(request.delegate)
		expect(derived.session).to be_equal(session)
		expect(derived.variables).to be_equal(variables)
		expect(derived.localization).to be_equal(localization)
		expect(derived.exception).to be_equal(exception)
	end
	
	it "does not normalize trusted derived request paths" do
		url = Protocol::URL::Relative.new("/internal/../target", request.url.query)
		derived = request.with(url: url)
		
		expect(derived.url.path).to be == Protocol::URL::Path["/internal/../target"]
	end
	
	it "preserves the original request path across multiple derived requests" do
		derived = request.with(url: request.url.with(path: "/find"))
		derived = derived.with(url: derived.url.with(path: "/lookup"))
		
		expect(derived.url.path).to be == Protocol::URL::Path["/lookup"]
		expect(derived.request_path).to be == Protocol::URL::Path["/search"]
	end
end
