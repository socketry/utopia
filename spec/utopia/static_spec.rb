#!/usr/bin/env rspec
# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2014-2022, by Samuel Williams.

require 'rack'
require 'rack/test'

require 'utopia/static'

module Utopia::StaticSpec
	describe Utopia::Static do
		include Rack::Test::Methods
		
		let(:app) {Rack::Builder.parse_file(File.expand_path('../static_spec.ru', __FILE__))}
		
		it "should give the correct mime type" do
			get "/test.txt"
			
			expect(last_response.headers['content-type']).to be == 'text/plain'
		end
		
		it "should return partial content" do
			get "/test.txt", {}, 'HTTP_RANGE' => 'bytes=1-4'
			
			expect(last_response.status).to be == 206 
			expect(last_response.content_length).to be == 4
			expect(last_response.body).to be == "ello"
		end
	end
end
