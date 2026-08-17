# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2026, by Samuel Williams.

require "utopia/static/mime_types"

describe Utopia::Static::MIME_TYPES do
	let(:extensions) {Utopia::Static::MimeTypeLoader.extensions_for(subject[:default])}
	let(:script_extensions) {Utopia::Static::MimeTypeLoader.extensions_for(subject[:scripts])}
	
	it "groups script extensions" do
		expect(script_extensions).to have_keys(
			".js" => be == "text/javascript",
			".mjs" => be == "text/javascript",
			".wasm" => be == "application/wasm",
		)
	end
	
	it "should give the correct mime type" do
		expect(extensions).to have_keys(
			".txt" => be == "text/plain",
			".mjs" => be == "text/javascript",
			".wasm" => be == "application/wasm",
			".webm" => be == "video/webm",
			".weba" => be == "audio/webm",
			".ogg" => be == "audio/vorbis",
			".spx" => be == "audio/speex",
			".html" => be == "text/html",
		)
	end
end

describe Utopia::Static::MimeTypeLoader do
	it "expands explicit extension mappings" do
		extensions = subject.extensions_for([["example", "application/example"]])
		
		expect(extensions).to have_keys(
			".example" => be == "application/example",
		)
	end
	
	it "rejects unknown file extensions" do
		expect do
			subject.extensions_for(["not-a-real-extension"])
		end.to raise_exception(subject::ExpansionError, message: be =~ /Unknown file extension/)
	end
	
	it "rejects unsupported definitions" do
		expect do
			subject.extensions_for([Object.new])
		end.to raise_exception(subject::ExpansionError, message: be =~ /Unsupported MIME type definition/)
	end
	
	it "wraps errors while expanding named groups" do
		expect do
			subject.extensions_for([:missing], {})
		end.to raise_exception(subject::ExpansionError, message: be =~ /Error while processing :missing/)
	end
end
