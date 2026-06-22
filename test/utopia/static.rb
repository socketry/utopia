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
	end
	
	it "should return partial content" do
		get "/test.txt", {"range" => "bytes=1-4"}
		
		expect(last_response.status).to be == 206
		expect(body.bytesize).to be == 4
		expect(body).to be == "ello"
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
