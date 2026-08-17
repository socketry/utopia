# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2014-2026, by Samuel Williams.

require "sus/fixtures/protocol/http/middleware_context"
require "utopia/application"
require "utopia/static"
require "utopia/content"
require "utopia/controller"
require "utopia/localization"

describe Utopia::Localization do
	include Sus::Fixtures::Protocol::HTTP::MiddlewareContext
	
	it "freezes its configuration" do
		default_locale = +"en"
		default_locales = [default_locale, nil]
		hosts = {/example\.com$/ => default_locale}
		ignore = ["/health"]
		middleware = Utopia::Localization::Middleware.new(
			Protocol::HTTP::Middleware::NotFound,
			locales: ["en"],
			default_locale: default_locale,
			default_locales: default_locales,
			hosts: hosts,
			ignore: ignore,
		)
		
		expect(middleware.freeze).to be_equal(middleware)
		expect(middleware).to be(:frozen?)
		expect(middleware.freeze).to be_equal(middleware)
		
		expect(middleware.all_locales).to be(:frozen?)
		expect(default_locales).to be(:frozen?)
		expect(default_locale).to be(:frozen?)
		expect(hosts).to be(:frozen?)
		expect(ignore).to be(:frozen?)
	end
	
	it "represents active and inactive localization preferences" do
		active = Utopia::Localization::Preferences.new(
			all_locales: ["en"],
			preferred_locales: ["en", nil],
			default_locale: "en",
		)
		inactive = Utopia::Localization::Preferences.new(
			all_locales: [],
			preferred_locales: [nil],
			default_locale: nil,
		)
		
		expect(active).to be(:localized?)
		expect(inactive).not.to be(:localized?)
		expect(inactive.localized_path("/example")).to be == "/example"
	end
	
	it "includes the default locale in the configured fallbacks" do
		middleware = Utopia::Localization::Middleware.new(
			Protocol::HTTP::Middleware::NotFound,
			locales: ["en", "ja"],
			default_locale: "en",
			default_locales: ["ja", nil],
		)
		request = Utopia::Request["GET", "/"]
		
		expect(middleware.preferred_locales(request)).to be == ["en", "ja", nil]
	end
	
	let(:middleware) do
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
		client.get "/localized.txt"
		
		expect(last_response.read).to be == "localized.en.txt"
	end
	
	it "should localize request based on path" do
		client.get "/en/localized.txt"
		expect(last_response.read).to be == "localized.en.txt"
		
		client.get "/de/localized.txt"
		expect(last_response.read).to be == "localized.de.txt"
		
		client.get "/ja/localized.txt"
		expect(last_response.read).to be == "localized.ja.txt"
	end
	
	it "extracts the path locale without decoding the remaining path" do
		middleware = Utopia::Localization::Middleware.new(
			Protocol::HTTP::Middleware::NotFound,
			locales: ["en"],
		)
		request = Utopia::Request["GET", "/en/files/a%2fb?token=1"]
		
		localized_request, locale = middleware.extract_path_locale(request)
		
		expect(locale).to be == "en"
		expect(localized_request.url.path).to be_a(Protocol::URL::Path)
		expect(localized_request.url.path).to be == "/files/a%2Fb"
		expect(localized_request.url.query).to be == "token=1"
		
		root_request, locale = middleware.extract_path_locale(Utopia::Request["GET", "/en"])
		
		expect(locale).to be == "en"
		expect(root_request.url.path).to be == "/"
		
		relative_request = Utopia::Request["GET", "en/files"]
		localized_request, locale = middleware.extract_path_locale(relative_request)
		
		expect(locale).to be_nil
		expect(localized_request).to be_equal(relative_request)
	end
	
	it "prefers an explicit path locale" do
		client.get "/ja/localized.txt", {"accept-language" => "en"}, authority: "foobar.de"
		
		expect(last_response.read).to be == "localized.ja.txt"
		expect(last_response.headers["content-language"].to_s).to be == "ja"
		expect(last_response.headers["content-location"].to_s).to be == "/ja/localized.txt"
	end
	
	it "should localize request based on domain name" do
		client.get "/localized.txt", nil, authority: "foobar.com"
		expect(last_response.read).to be == "localized.en.txt"
		
		client.get "/localized.txt", nil, authority: "foobar.de"
		expect(last_response.read).to be == "localized.de.txt"
		
		client.get "/localized.txt", nil, authority: "foobar.co.jp"
		expect(last_response.read).to be == "localized.ja.txt"
	end
	
	it "should get a non-localized resource" do
		client.get "/en/test.txt"
		expect(last_response.read).to be == "Hello World!"
	end
	
	it "should respond with accepted language localization" do
		client.get "/localized.txt", {"accept-language" => "ja,en"}
		
		expect(last_response.read).to be == "localized.ja.txt"
		expect(last_response.headers["content-language"].to_s).to be == "ja"
		expect(last_response.headers["content-location"].to_s).to be == "/ja/localized.txt"
	end
	
	it "matches less specific accepted languages" do
		application = Utopia::Application.build(Protocol::HTTP::Middleware.for do |request|
			Utopia::Response.text(request.localization.preferred_locales.compact.join(","))
		end) do
			use Utopia::Localization, locales: ["en-NZ", "en-US"], default_locale: "en-NZ"
		end
		
		response = application.call(Protocol::HTTP::Request["GET", "/", {"accept-language" => "en"}])
		
		expect(response.read).to be == "en-NZ"
	end
	
	it "ignores malformed accepted languages" do
		client.get "/localized.txt", {"accept-language" => "not a language"}
		
		expect(last_response.read).to be == "localized.en.txt"
	end
	
	it "resolves localized content templates" do
		client.get "/page", {"accept-language" => "ja,en"}
		
		expect(last_response.read).to be == "localized.ja.content\n"
		expect(last_response.headers["content-language"].to_s).to be == "ja"
	end
	
	it "falls back to the next available localized content template" do
		client.get "/page", {"accept-language" => "de"}
		
		expect(last_response.read).to be == "localized.en.content\n"
		expect(last_response.headers["content-language"].to_s).to be == "en"
	end
	
	it "resolves unlocalized content as the final fallback" do
		client.get "/fallback", {"accept-language" => "ja,en"}
		
		expect(last_response.read).to be == "unlocalized.content\n"
		expect(last_response.headers["content-language"]).to be_nil
	end
	
	it "passes through when no localized content representation exists" do
		delegate = Protocol::HTTP::Middleware.for do |_request|
			Utopia::Response.text("Fallback")
		end
		middleware = Utopia::Content::Middleware.new(
			delegate,
			root: File.expand_path(".localization", __dir__),
		)
		request = Utopia::Request["GET", "/missing"]
		request.localization = Utopia::Localization::Preferences.new(
			all_locales: ["en"],
			preferred_locales: ["en"],
			default_locale: "en",
		)
		
		response = middleware.call(request)
		
		expect(response.status).to be == 200
		expect(response.read).to be == "Fallback"
	ensure
		response&.close
		middleware&.close
	end
	
	it "keeps request preferences immutable while resolving content" do
		observed = nil
		application = Utopia::Application.build(Protocol::HTTP::Middleware.for do |request|
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
		client.get "/all_locales"
		expect(last_response.read).to be == "en,ja,de"
	end
	
	it "should get the default locale" do
		client.get "/default_locale"
		expect(last_response.read).to be == "en"
	end
	
	it "should get the selected locale (german)" do
		client.get "/locale", nil, authority: "foobar.de"
		expect(last_response.read).to be == "de"
	end
	
	it "invokes the application once" do
		calls = 0
		application = Utopia::Application.build(Protocol::HTTP::Middleware.for do |_request|
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
		application = Utopia::Application.build(Protocol::HTTP::Middleware.for do |request|
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
