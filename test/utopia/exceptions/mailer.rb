# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2016-2026, by Samuel Williams.

require "sus/fixtures/protocol/http/middleware_context"
require "utopia/application"
require "utopia/exceptions"
require "utopia/controller"

describe Utopia::Exceptions::Mailer do
	include Sus::Fixtures::Protocol::HTTP::MiddlewareContext
	
	let(:middleware) do
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
		client.headers["accept"] = "text/plain"
		
		expect{client.get "/blow"}.to raise_exception(StandardError, message: be =~ /Arrrh/)
		
		last_mail = Mail::TestMailer.deliveries.last
		
		expect(last_mail.to_s).to be(:include?, "GET")
		expect(last_mail.to_s).to be(:include?, "/blow")
		expect(last_mail.to_s).to be(:include?, "request.ip")
		expect(last_mail.to_s).to be(:include?, "header[")
		expect(last_mail.to_s).to be(:include?, "TharSheBlows")
	end
	
	it "reports application syntax errors" do
		expect{client.get "/syntax-error"}.to raise_exception(SyntaxError, message: be =~ /Invalid application syntax/)
		
		last_mail = Mail::TestMailer.deliveries.last
		expect(last_mail.to_s).to be(:include?, "SyntaxError")
	end
	
	it "does not report process exceptions" do
		expect{client.get "/interrupt"}.to raise_exception(Interrupt, message: be =~ /Application interrupted/)
		
		expect(Mail::TestMailer.deliveries).to be(:empty?)
	end
	
	it "extracts rewindable request bodies" do
		request = Utopia::Request["POST", "/", {}, ["Hello", " World!"]]
		request.body.read
		mailer = subject.new(Protocol::HTTP::Middleware::NotFound, delivery_method: nil)
		
		expect(mailer.send(:extract_body, request)).to be == "Hello World!"
	end
	
	it "does not extract streaming request bodies" do
		body = Object.new
		def body.rewindable? = false
		request = Struct.new(:body).new(body)
		mailer = subject.new(Protocol::HTTP::Middleware::NotFound, delivery_method: nil)
		
		expect(mailer.send(:extract_body, request)).to be_nil
	end
end
