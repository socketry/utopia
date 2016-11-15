#!/usr/bin/env rspec
# Copyright, 2014, by Samuel G. D. Williams. <http://www.codeotaku.com>
# 
# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:
# 
# The above copyright notice and this permission notice shall be included in
# all copies or substantial portions of the Software.
# 
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
# THE SOFTWARE.

require 'rack'
require 'rack/test'

require 'utopia/static'
require 'utopia/content'
require 'utopia/controller'
require 'utopia/localization'

module Utopia::LocalizationSpec
	describe Utopia::Localization do
		include Rack::Test::Methods
		
		let(:app) {Rack::Builder.parse_file(File.expand_path('../localization_spec.ru', __FILE__)).first}
		
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
