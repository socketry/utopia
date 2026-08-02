# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2014-2025, by Samuel Williams.

require "utopia/static"
require_relative "protocol_application"

describe Utopia::Static do
	include ProtocolApplication
	
	let(:app) do
		root = File.expand_path(".static", __dir__)
		
		Utopia::Application.build do
			use Utopia::Static, root: root
		end
	end
	
	it "should give the correct mime type" do
		get "/test.txt"
		
		expect(last_response.headers["content-type"]).to be == "text/plain"
		expect(last_response.body).to be_a(Protocol::HTTP::Body::File)
	end
	
	it "should return partial content" do
		get "/test.txt", {"range" => "bytes=1-4"}
		
		expect(last_response.status).to be == 206
		expect(body.bytesize).to be == 4
		expect(body).to be == "ello"
	end
	
	it "should clamp partial content to the file size" do
		get "/test.txt", {"range" => "bytes=1-999"}
		
		expect(last_response.status).to be == 206
		expect(last_response.headers["content-range"]).to be == "bytes 1-11/12"
		expect(body).to be == "ello World!"
	end
	
	it "should clamp suffix ranges to the file size" do
		get "/test.txt", {"range" => "bytes=-999"}
		
		expect(last_response.status).to be == 206
		expect(last_response.headers["content-range"]).to be == "bytes 0-11/12"
		expect(body).to be == "Hello World!"
	end
	
	it "should ignore unsatisfiable ranges" do
		get "/test.txt", {"range" => "bytes=999-1000"}
		
		expect(last_response.status).to be == 200
		expect(body).to be == "Hello World!"
	end
	
	it "should ignore multiple ranges" do
		get "/test.txt", {"range" => "bytes=0-1,4-5"}
		
		expect(last_response.status).to be == 200
		expect(body).to be == "Hello World!"
	end
	
	it "should ignore unsupported range units" do
		get "/test.txt", {"range" => "example=alpha"}
		
		expect(last_response.status).to be == 200
		expect(body).to be == "Hello World!"
	end
	
	it "should reject malformed ranges" do
		expect do
			get "/test.txt", {"range" => "bytes=4-1"}
		end.to raise_exception(Protocol::HTTP::Header::Range::ParseError)
	end
	
	describe Utopia::Static::MIME_TYPES do
		let(:extensions) {Utopia::Static::MimeTypeLoader.extensions_for(subject[:default])}
		
		it "should give the correct mime type" do
			expect(extensions).to have_keys(
				".txt" => be == "text/plain",
				".webm" => be == "video/webm",
				".weba" => be == "audio/webm",
				".html" => be == "text/html",
			)
		end
	end
end
