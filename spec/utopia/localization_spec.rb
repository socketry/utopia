#!/usr/bin/env rspec
# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2014-2022, by Samuel Williams.

require 'rack'
require 'rack/test'

require 'utopia/static'
require 'utopia/content'
require 'utopia/controller'
require 'utopia/localization'

module Utopia::LocalizationSpec
	describe Utopia::Localization do
		include Rack::Test::Methods
		
		let(:app) {Rack::Builder.parse_file(File.expand_path('../localization_spec.ru', __FILE__))}
		
		it "should respond with default localization" do
			get '/localized.txt'
			
			expect(last_response.body).to be == 'localized.en.txt'
		end
		
		it "should localize request based on path" do
			get '/en/localized.txt'
			expect(last_response.body).to be == 'localized.en.txt'
			
			get '/de/localized.txt'
			expect(last_response.body).to be == 'localized.de.txt'
			
			get '/ja/localized.txt'
			expect(last_response.body).to be == 'localized.ja.txt'
		end
		
		it "should localize request based on domain name" do
			get '/localized.txt', {}, 'HTTP_HOST' => 'foobar.com'
			expect(last_response.body).to be == 'localized.en.txt'
			
			get '/localized.txt', {}, 'HTTP_HOST' => 'foobar.de'
			expect(last_response.body).to be == 'localized.de.txt'
			
			get '/localized.txt', {}, 'HTTP_HOST' => 'foobar.co.jp'
			expect(last_response.body).to be == 'localized.ja.txt'
		end
		
		it "should get a non-localized resource" do
			get "/en/test.txt"
			expect(last_response.body).to be == 'Hello World!'
		end
		
		it "should respond with accepted language localization" do
			get '/localized.txt', {}, 'HTTP_ACCEPT_LANGUAGE' => 'ja,en'
			
			expect(last_response.body).to be == 'localized.ja.txt'
		end
		
		it "should get a list of all localizations" do
			get '/all_locales'
			expect(last_response.body).to be == 'en,ja,de'
		end
		
		it "should get the default locale" do
			get '/default_locale'
			expect(last_response.body).to be == 'en'
		end
		
		it "should get the current locale (german)" do
			get '/current_locale', {}, 'HTTP_HOST' => 'foobar.de'
			expect(last_response.body).to be == 'de'
		end
	end
end
