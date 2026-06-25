# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2016-2025, by Samuel Williams.

require "utopia/exceptions"
require "utopia/controller"
require_relative "../protocol_application"

describe Utopia::Exceptions::Mailer do
	include ProtocolApplication
	
	let(:app) do
		root = File.expand_path(".handler", __dir__)
		
		Utopia::Application.build do
			use Utopia::Exceptions::Mailer,
				delivery_method: :test,
				from: "test@localhost"
			
			use Utopia::Controller, root: root
		end
	end
	
	def before
		Mail::TestMailer.deliveries.clear
		
		super
	end
	
	it "should send an email to report the failure" do
		header "Accept", "text/plain"
		
		expect{get "/blow"}.to raise_exception(StandardError, message: be =~ /Arrrh/)
		
		last_mail = Mail::TestMailer.deliveries.last
		
		expect(last_mail.to_s).to be(:include?, "GET")
		expect(last_mail.to_s).to be(:include?, "/blow")
		expect(last_mail.to_s).to be(:include?, "request.ip")
		expect(last_mail.to_s).to be(:include?, "header[")
		expect(last_mail.to_s).to be(:include?, "TharSheBlows")
	end
end
