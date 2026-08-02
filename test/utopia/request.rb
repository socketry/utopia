# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2026, by Samuel Williams.

require "protocol/http/request"
require "protocol/multipart/form_data"
require "utopia/request"

require "stringio"

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
	
	it "provides path information" do
		expect(request.path_info).to be == "/search"
		expect(request.query).to be == "q=utopia&tag[]=ruby&tag[]=async"
	end
	
	it "updates path information while preserving query string" do
		request.path_info = "/find"
		
		expect(request.path).to be == "/find?q=utopia&tag[]=ruby&tag[]=async"
		expect(request.path_info).to be == "/find"
		expect(request.request_path).to be == "/search"
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
	
	it "decodes URL encoded form arguments" do
		request.headers["content-type"] = "application/x-www-form-urlencoded"
		request.body = Protocol::HTTP::Body::Buffered.wrap("user[name]=Samuel&query=hello+world")
		
		expect(request.form_arguments).to be == {
			"user" => {"name" => "Samuel"},
			"query" => "hello world"
		}
	end
	
	it "combines query and form arguments" do
		request.headers["content-type"] = "application/x-www-form-urlencoded"
		request.body = Protocol::HTTP::Body::Buffered.wrap("q=form&token=abc")
		
		expect(request.arguments).to be == {
			"q" => "form",
			"tag" => ["ruby", "async"],
			"token" => "abc"
		}
	end
	
	it "clears decoded form arguments when assigning a new body" do
		request.headers["content-type"] = "application/x-www-form-urlencoded"
		request.body = Protocol::HTTP::Body::Buffered.wrap("value=one")
		expect(request.form_arguments).to be == {"value" => "one"}
		
		request.body = Protocol::HTTP::Body::Buffered.wrap("value=two")
		expect(request.form_arguments).to be == {"value" => "two"}
	end
	
	it "leaves unsupported request bodies untouched" do
		request.headers["content-type"] = "application/json"
		request.body = Protocol::HTTP::Body::Buffered.wrap('{"name":"Samuel"}')
		
		expect(request.form_arguments).to be(:empty?)
		expect(request.body.read).to be == '{"name":"Samuel"}'
	end
	
	it "decodes multipart form arguments and uploads" do
		form = Protocol::Multipart::FormData.new
		form.add_field("user[name]", "Samuel")
		form.parts << Protocol::Multipart::StringPart.new(
			{
				"content-disposition" => 'form-data; name="avatar"; filename="samuel.txt"',
				"content-type" => "text/plain"
			},
			"Hello!"
		)
		
		body = StringIO.new
		form.call(body)
		request.headers["content-type"] = form.headers["content-type"]
		request.body = Protocol::HTTP::Body::Buffered.wrap(body.string)
		
		arguments = request.form_arguments
		upload = arguments["avatar"]
		
		expect(arguments["user"]).to be == {"name" => "Samuel"}
		expect(upload).to be_a(Utopia::Request::Upload)
		expect(upload.filename).to be == "samuel.txt"
		expect(upload.content_type).to be == "text/plain"
		expect(upload.size).to be == 6
		expect(upload.tempfile.read).to be == "Hello!"
	ensure
		upload&.tempfile&.close!
	end
	
	it "decodes quoted multipart parameters" do
		boundary = "quoted-boundary"
		body = <<~MULTIPART.gsub("\n", "\r\n")
			--#{boundary}
			Content-Disposition: form-data; name="file"; filename="a\\\"b.txt"
			Content-Type: text/plain
			
			Hello!
			--#{boundary}--
		MULTIPART
		
		request.headers["content-type"] = %(multipart/form-data; boundary="#{boundary}")
		request.body = Protocol::HTTP::Body::Buffered.wrap(body)
		upload = request.form_arguments["file"]
		
		expect(upload.filename).to be == 'a"b.txt'
	ensure
		upload&.tempfile&.close!
	end
	
	it "requires a multipart boundary" do
		request.headers["content-type"] = "multipart/form-data"
		request.body = Protocol::HTTP::Body::Buffered.wrap("")
		
		expect{request.form_arguments}.to raise_exception(ArgumentError, message: be =~ /missing a boundary/)
	end
	
	it "does not expose ambiguous Rack request accessors" do
		expect(request).not.to be(:respond_to?, :params)
		expect(request).not.to be(:respond_to?, :[])
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
		expect(request.locale).to be_nil
		expect(request.exception).to be_nil
	end
	
	it "provides request metadata" do
		request.scheme = "https"
		request.authority = "example.com"
		request.headers["referer"] = "/from"
		
		expect(request.scheme).to be == "https"
		expect(request.host).to be == "example.com"
		expect(request.url).to be == "https://example.com/search?q=utopia&tag[]=ruby&tag[]=async"
		expect(request.referrer).to be == "/from"
	end
	
	it "builds derived requests" do
		session = Object.new
		variables = Object.new
		request.session = session
		request.variables = variables
		request.locale = "en"
		exception = StandardError.new("Boom")
		request.exception = exception
		
		derived = request.with(method: "GET", path_info: "/find")
		
		expect(derived).not.to be_equal(request)
		expect(derived.method).to be == "GET"
		expect(derived.path).to be == "/find?q=utopia&tag[]=ruby&tag[]=async"
		expect(derived.request_path).to be == "/search"
		expect(derived.delegate).not.to be_equal(request.delegate)
		expect(derived.session).to be_equal(session)
		expect(derived.variables).to be_equal(variables)
		expect(derived.locale).to be == "en"
		expect(derived.exception).to be_equal(exception)
	end
	
	it "preserves the original request path across multiple derived requests" do
		derived = request.with(path_info: "/find")
		derived = derived.with(path_info: "/lookup")
		
		expect(derived.path_info).to be == "/lookup"
		expect(derived.request_path).to be == "/search"
	end
end
