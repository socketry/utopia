# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2014-2025, by Samuel Williams.

require "sus/fixtures/protocol/http/middleware_context"
require "utopia/application"
require "utopia/static"

describe Utopia::Static do
	include Sus::Fixtures::Protocol::HTTP::MiddlewareContext
	
	let(:middleware) do
		root = File.expand_path(".static", __dir__)
		
		Utopia::Application.build do
			use Utopia::Static, root: root
		end
	end
	
	it "should give the correct mime type" do
		client.get "/test.txt"
		
		expect(last_response.headers["content-type"]).to be == "text/plain"
		expect(last_response.body).to be_a(Protocol::HTTP::Body::File)
	end
	
	it "returns not modified for matching entity tags" do
		client.get "/test.txt"
		etag = last_response.headers["etag"]
		
		expect(etag).to be(:match?, /\AW\/"[0-9a-f]{40}"\z/)
		
		client.get "/test.txt", {"if-none-match" => etag}
		expect(last_response.status).to be == 304
		
		client.get "/test.txt", {"if-none-match" => etag.delete_prefix("W/")}
		expect(last_response.status).to be == 304
		
		client.get "/test.txt", {"if-none-match" => "*"}
		expect(last_response.status).to be == 304
	end
	
	it "gives entity tags precedence over modification dates" do
		client.get "/test.txt", {
			"if-none-match" => '"different"',
			"if-modified-since" => (Time.now + 3600).httpdate,
		}
		
		expect(last_response.status).to be == 200
	end
	
	it "returns not modified when the modification time matches" do
		client.get "/test.txt"
		last_modified = last_response.headers["last-modified"]
		
		client.get "/test.txt", {"if-modified-since" => last_modified}
		
		expect(last_response.status).to be == 304
	end
	
	it "returns modified when the modification time is newer" do
		client.get "/test.txt"
		last_modified = last_response.headers["last-modified"].to_time
		
		client.get "/test.txt", {"if-modified-since" => (last_modified - 1).httpdate}
		
		expect(last_response.status).to be == 200
	end
	
	it "should return partial content" do
		client.get "/test.txt", {"range" => "bytes=1-4"}
		
		expect(last_response.status).to be == 206
		body = last_response.read
		expect(body.bytesize).to be == 4
		expect(body).to be == "ello"
	end
	
	it "should clamp partial content to the file size" do
		client.get "/test.txt", {"range" => "bytes=1-999"}
		
		expect(last_response.status).to be == 206
		expect(last_response.headers["content-range"]).to be == "bytes 1-11/12"
		expect(last_response.read).to be == "ello World!"
	end
	
	it "should clamp suffix ranges to the file size" do
		client.get "/test.txt", {"range" => "bytes=-999"}
		
		expect(last_response.status).to be == 206
		expect(last_response.headers["content-range"]).to be == "bytes 0-11/12"
		expect(last_response.read).to be == "Hello World!"
	end
	
	it "should ignore unsatisfiable ranges" do
		client.get "/test.txt", {"range" => "bytes=999-1000"}
		
		expect(last_response.status).to be == 200
		expect(last_response.read).to be == "Hello World!"
	end
	
	it "should ignore multiple ranges" do
		client.get "/test.txt", {"range" => "bytes=0-1,4-5"}
		
		expect(last_response.status).to be == 200
		expect(last_response.read).to be == "Hello World!"
	end
	
	it "should ignore unsupported range units" do
		client.get "/test.txt", {"range" => "example=alpha"}
		
		expect(last_response.status).to be == 200
		expect(last_response.read).to be == "Hello World!"
	end
	
	it "should reject malformed ranges" do
		expect do
			client.get "/test.txt", {"range" => "bytes=4-1"}
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
