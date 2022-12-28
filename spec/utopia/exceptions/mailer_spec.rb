#!/usr/bin/env rspec
# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2016-2020, by Samuel Williams.

require_relative '../rack_helper'

require 'utopia/exceptions'
require 'utopia/controller'

RSpec.describe Utopia::Exceptions::Mailer do
	include_context "rack app", File.expand_path("mailer_spec.ru", __dir__)
	
	before(:each) do
		Mail::TestMailer.deliveries.clear
	end
	
	it "should send an email to report the failure" do
		expect{get "/blow"}.to raise_error('Arrrh!')
		
		last_mail = Mail::TestMailer.deliveries.last
		
		expect(last_mail.to_s).to include("GET", "blow", "request.ip", "HTTP_", "TharSheBlows")
	end
end
