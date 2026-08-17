# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2014-2026, by Samuel Williams.

require "tmpdir"

require "sus/fixtures/protocol/http/middleware_context"
require "utopia/application"
require "utopia/static"

describe Utopia::Static do
	include Sus::Fixtures::Protocol::HTTP::MiddlewareContext
	
	it "freezes its configuration" do
		cache_control = proc{"private"}
		middleware = Utopia::Static::Middleware.new(
			Protocol::HTTP::Middleware::NotFound,
			root: File.expand_path(".static", __dir__),
			cache_control: cache_control,
		)
		
		expect(middleware.freeze).to be_equal(middleware)
		expect(middleware).to be(:frozen?)
		expect(middleware.freeze).to be_equal(middleware)
		
		expect(middleware.instance_variable_get(:@root)).to be(:frozen?)
		expect(middleware.extensions).to be(:frozen?)
		expect(cache_control).to be(:frozen?)
	end
	
	it "computes cache control from the served file" do
		served_file = nil
		application = Utopia::Application.build do
			use Utopia::Static,
				root: File.expand_path(".static", __dir__),
				cache_control: proc{|file| served_file = file; "private, max-age=#{file.bytesize}"}
		end
		
		response = application.call(Protocol::HTTP::Request["GET", "/test.txt"])
		
		expect(response.headers["cache-control"]).to be == ["private", "max-age=12"]
		expect(served_file).to be_a(Utopia::Static::LocalFile)
	ensure
		response&.close
		application.close
	end
	
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
	
	it "normalizes the extension for media type lookup" do
		client.get "/uppercase.TXT"
		
		expect(last_response.status).to be == 200
		expect(last_response.headers["content-type"]).to be == "text/plain"
		expect(last_response.read).to be == "Uppercase extension!\n"
	end
	
	it "serves JavaScript modules" do
		client.get "/module.mjs"
		
		expect(last_response.status).to be == 200
		expect(last_response.headers["content-type"]).to be == "text/javascript"
		expect(last_response.read).to be == "export default true;\n"
	end
	
	it "serves WebAssembly modules" do
		client.get "/module.wasm"
		
		expect(last_response.status).to be == 200
		expect(last_response.headers["content-type"]).to be == "application/wasm"
		expect(last_response.read).to be == "WebAssembly\n"
	end
	
	it "serves HEAD requests without opening a response body" do
		client.head "/test.txt"
		
		expect(last_response.status).to be == 200
		expect(last_response.headers["content-length"]).to be == "12"
		expect(last_response.body).to be_a(Protocol::HTTP::Body::Head)
		expect(last_response.body.length).to be == 12
		expect(last_response.read).to be_nil
	end
	
	it "passes non-retrieval methods through" do
		client.post "/test.txt"
		expect(last_response.status).to be == 404
		
		client.delete "/test.txt"
		expect(last_response.status).to be == 404
	end
	
	it "resolves encoded file names beneath the static root" do
		client.get "/test%2Etxt"
		
		expect(last_response.status).to be == 200
		expect(last_response.read).to be == "Hello World!"
	end
	
	it "rejects encoded path separators" do
		expect do
			client.get "/directory%2F..%2Ftest.txt"
		end.to raise_exception(ArgumentError, message: be =~ /invalid characters/)
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
	
	it "ignores ranges with stale entity tags" do
		client.get "/test.txt", {
			"range" => "bytes=1-4",
			"if-range" => '"stale"',
		}
		
		expect(last_response.status).to be == 200
		expect(last_response.headers["content-range"]).to be_nil
		expect(last_response.read).to be == "Hello World!"
	end
	
	it "does not use weak entity tags for If-Range" do
		client.get "/test.txt"
		etag = last_response.headers["etag"]
		
		client.get "/test.txt", {
			"range" => "bytes=1-4",
			"if-range" => etag,
		}
		
		expect(last_response.status).to be == 200
		expect(last_response.headers["content-range"]).to be_nil
		expect(last_response.read).to be == "Hello World!"
	end
	
	it "does not use weak modification dates for If-Range" do
		client.get "/test.txt"
		last_modified = last_response.headers["last-modified"]
		
		client.get "/test.txt", {
			"range" => "bytes=1-4",
			"if-range" => last_modified,
		}
		
		expect(last_response.status).to be == 200
		expect(last_response.headers["content-range"]).to be_nil
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
	
	it "expands relative roots during initialization" do
		Dir.mktmpdir do |directory|
			root = File.join(directory, "public")
			Dir.mkdir(root)
			File.write(File.join(root, "test.txt"), "Expanded root!")
			
			application = Dir.chdir(directory) do
				Utopia::Application.build do
					use Utopia::Static, root: "public"
				end
			end
			
			begin
				Dir.mktmpdir do |working_directory|
					response = Dir.chdir(working_directory) do
						application.call(Protocol::HTTP::Request["GET", "/test.txt"])
					end
					
					begin
						expect(response.status).to be == 200
						expect(response.read).to be == "Expanded root!"
					ensure
						response.close
					end
				end
			ensure
				application.close
			end
		end
	end
end
