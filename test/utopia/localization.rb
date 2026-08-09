# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2014-2025, by Samuel Williams.

require "utopia/static"
require "utopia/content"
require "utopia/controller"
require "utopia/localization"
require_relative "protocol_application"

describe Utopia::Localization do
	include ProtocolApplication
	
	let(:app) do
		root = File.expand_path(".localization", __dir__)
		
		Utopia::Application.build do
			use Utopia::Localization,
				locales: ["en", "ja", "de"],
				hosts: {/foobar\.com$/ => "en", /foobar\.co\.jp$/ => "ja", /foobar\.de$/ => "de"}
			
			use Utopia::Static, root: root
			use Utopia::Controller, root: root
			use Utopia::Content, root: root
		end
	end
	
	it "should respond with default localization" do
		get "/localized.txt"
		
		expect(body).to be == "localized.en.txt"
	end
	
	it "should localize request based on path" do
		get "/en/localized.txt"
		expect(body).to be == "localized.en.txt"
		
		get "/de/localized.txt"
		expect(body).to be == "localized.de.txt"
		
		get "/ja/localized.txt"
		expect(body).to be == "localized.ja.txt"
	end
	
	it "prefers an explicit path locale" do
		get "/ja/localized.txt", {"host" => "foobar.de", "accept-language" => "en"}
		
		expect(body).to be == "localized.ja.txt"
		expect(last_response.headers["content-language"].to_s).to be == "ja"
		expect(last_response.headers["content-location"].to_s).to be == "/ja/localized.txt"
	end
	
	it "should localize request based on domain name" do
		get "/localized.txt", {"host" => "foobar.com"}
		expect(body).to be == "localized.en.txt"
		
		get "/localized.txt", {"host" => "foobar.de"}
		expect(body).to be == "localized.de.txt"
		
		get "/localized.txt", {"host" => "foobar.co.jp"}
		expect(body).to be == "localized.ja.txt"
	end
	
	it "should get a non-localized resource" do
		get "/en/test.txt"
		expect(body).to be == "Hello World!"
	end
	
	it "should respond with accepted language localization" do
		get "/localized.txt", {"accept-language" => "ja,en"}
		
		expect(body).to be == "localized.ja.txt"
		expect(last_response.headers["content-language"].to_s).to be == "ja"
		expect(last_response.headers["content-location"].to_s).to be == "/ja/localized.txt"
	end
	
	it "resolves localized content templates" do
		get "/page", {"accept-language" => "ja,en"}
		
		expect(body).to be == "localized.ja.content\n"
		expect(last_response.headers["content-language"].to_s).to be == "ja"
	end
	
	it "falls back to the next available localized content template" do
		get "/page", {"accept-language" => "de"}
		
		expect(body).to be == "localized.en.content\n"
		expect(last_response.headers["content-language"].to_s).to be == "en"
	end
	
	it "resolves unlocalized content as the final fallback" do
		get "/fallback", {"accept-language" => "ja,en"}
		
		expect(body).to be == "unlocalized.content\n"
		expect(last_response.headers["content-language"]).to be_nil
	end
	
	it "keeps request preferences immutable while resolving content" do
		observed = nil
		application = Utopia::Application.build(lambda do |request|
			observed = request.localization
			Utopia::Response.text("Fallback")
		end) do
			use Utopia::Localization, locales: ["en", "ja"], default_locale: "en"
		end
		
		response = application.call(Protocol::HTTP::Request["GET", "/missing", {"accept-language" => "ja"}])
		
		expect(response.read).to be == "Fallback"
		expect(observed.preferred_locales).to be == ["ja", "en", nil]
		expect(observed.locale).to be == "ja"
		expect(observed).to be(:frozen?)
		expect(observed.preferred_locales).to be(:frozen?)
		expect{observed.preferred_locales.first << "-NZ"}.to raise_exception(FrozenError)
	end
	
	it "should get a list of all localizations" do
		get "/all_locales"
		expect(body).to be == "en,ja,de"
	end
	
	it "should get the default locale" do
		get "/default_locale"
		expect(body).to be == "en"
	end
	
	it "should get the selected locale (german)" do
		get "/locale", {"host" => "foobar.de"}
		expect(body).to be == "de"
	end
	
	it "invokes the application once" do
		calls = 0
		application = Utopia::Application.build(lambda do |_request|
			calls += 1
			Utopia::Response.text("Failure", 404)
		end) do
			use Utopia::Localization, locales: ["en"], default_locale: "en"
		end
		
		response = application.call(Protocol::HTTP::Request["GET", "/missing"])
		
		expect(calls).to be == 1
		expect(response.status).to be == 404
		expect(response.read).to be == "Failure"
	end
	
	it "passes ignored requests through without localization" do
		observed = nil
		application = Utopia::Application.build(lambda do |request|
			observed = request.localization
			Utopia::Response.text("Ignored")
		end) do
			use Utopia::Localization, locales: ["en"], ignore: ["/ignored"]
		end
		
		response = application.call(Protocol::HTTP::Request["GET", "/ignored"])
		
		expect(response.read).to be == "Ignored"
		expect(response.headers["vary"]).to be_nil
		expect(observed).to be_nil
	end
end
