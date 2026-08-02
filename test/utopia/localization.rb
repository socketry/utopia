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
			
			use Utopia::Controller, root: root
			use Utopia::Static, root: root
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
	end
	
	it "should get a list of all localizations" do
		get "/all_locales"
		expect(body).to be == "en,ja,de"
	end
	
	it "should get the default locale" do
		get "/default_locale"
		expect(body).to be == "en"
	end
	
	it "should get the current locale (german)" do
		get "/current_locale", {"host" => "foobar.de"}
		expect(body).to be == "de"
	end
end
