#!/usr/bin/env rspec
# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2015-2022, by Samuel Williams.

require_relative '../rack_helper'

require 'utopia/exceptions'
require 'utopia/controller'

RSpec.describe Utopia::Exceptions::Handler do
	include_context "rack app", File.expand_path("handler_spec.ru", __dir__)
	
	it "should successfully call the controller method" do
		# This request will raise an exception, and then redirect to the /exception url which will fail again, and cause a fatal error.
		get "/blow?fatal=true"
		
		expect(last_response.status).to be == 500
		expect(last_response.headers['content-type']).to be == 'text/plain'
		expect(last_response.body).to be_include 'fatal error'
	end
	
	it "should fail with a 500 error" do
		get "/blow"
		
		expect(last_response.status).to be == 500
		expect(last_response.body).to be_include 'Error Will Robertson'
	end
end
