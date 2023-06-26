# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2016-2023, by Samuel Williams.

require 'a_rack_application'

require 'utopia/exceptions'
require 'utopia/controller'

describe Utopia::Exceptions::Mailer do
	include_context ARackApplication, File.expand_path("mailer.ru", __dir__)
	
	def before
		Mail::TestMailer.deliveries.clear
		
		super
	end
	
	it "should send an email to report the failure" do
		expect{get "/blow"}.to raise_exception(StandardError, message: be =~ /Arrrh/)
		
		last_mail = Mail::TestMailer.deliveries.last
		
		expect(last_mail.to_s).to be(:include?, "GET")
		expect(last_mail.to_s).to be(:include?, "/blow")
		expect(last_mail.to_s).to be(:include?, "request.ip")
		expect(last_mail.to_s).to be(:include?, "HTTP_")
		expect(last_mail.to_s).to be(:include?, "TharSheBlows")
	end
end
