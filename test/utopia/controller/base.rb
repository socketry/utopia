# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2026, by Samuel Williams.

require "protocol/http/request"
require "protocol/multipart/form_data"
require "utopia/controller/base"
require "utopia/request"

require "stringio"

describe Utopia::Controller::Base do
	let(:controller) {subject.new}
	
	it "parses request bodies independently of the request method" do
		request = Utopia::Request[
			"QUERY",
			"/search",
			{"content-type" => "application/json"},
			Protocol::HTTP::Body::Buffered.wrap('{"name":"Samuel"}')
		]
		
		expect(controller.parse_body(request)).to be == {"name" => "Samuel"}
	end
	
	it "returns nil when there is no request body" do
		request = Utopia::Request["GET", "/"]
		
		expect(controller.parse_body(request)).to be_nil
	end
	
	it "supports action-specific content parsers" do
		parser = Protocol::Content::Parser.build do |parser|
			parser.register("application/example") do |input|
				input.read.upcase
			end
		end
		
		request = Utopia::Request[
			"POST",
			"/",
			{"content-type" => "application/example"},
			Protocol::HTTP::Body::Buffered.wrap("parsed")
		]
		
		expect(controller.parse_body(request, parser: parser)).to be == "PARSED"
	end
	
	it "propagates content parsing errors" do
		request = Utopia::Request[
			"POST",
			"/",
			{"content-type" => "application/octet-stream"},
			Protocol::HTTP::Body::Buffered.wrap("data")
		]
		
		expect do
			controller.parse_body(request)
		end.to raise_exception(Protocol::Content::UnsupportedMediaTypeError)
	end
	
	it "streams multipart uploads through the parse block" do
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
		request = Utopia::Request[
			"POST",
			"/",
			form.headers,
			Protocol::HTTP::Body::Buffered.wrap(body.string)
		]
		uploads = {}
		
		result = controller.parse_body(request) do |name, value|
			case value
			when Protocol::Multipart::FormData::Upload
				content = String.new.b
				value.each{|chunk| content << chunk}
				uploads[name] = content
				value.filename
			else
				value
			end
		end
		
		expect(result).to be == {
			"user" => {"name" => "Samuel"},
			"avatar" => "samuel.txt"
		}
		expect(uploads).to be == {"avatar" => "Hello!"}
	end
end
