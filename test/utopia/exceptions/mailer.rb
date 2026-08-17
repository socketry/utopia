# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2016-2026, by Samuel Williams.

require "sus/fixtures/protocol/http/middleware_context"
require "sus/fixtures/console/captured_logger"
require "utopia/application"
require "utopia/exceptions"
require "utopia/controller"

describe Utopia::Exceptions::Mailer do
	include Sus::Fixtures::Protocol::HTTP::MiddlewareContext
	include Sus::Fixtures::Console::CapturedLogger
	
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
	
	it "freezes its configuration" do
		to = +"postmaster@example.com"
		from = +"utopia@example.com"
		template = +"%{exception}"
		delivery_method = [:test, {}]
		middleware = subject.new(
			Protocol::HTTP::Middleware::NotFound,
			to: to,
			from: from,
			subject: template,
			delivery_method: delivery_method,
		)
		
		expect(middleware.freeze).to be_equal(middleware)
		expect(middleware).to be(:frozen?)
		expect(middleware.freeze).to be_equal(middleware)
		
		expect(to).to be(:frozen?)
		expect(from).to be(:frozen?)
		expect(template).to be(:frozen?)
		expect(delivery_method).to be(:frozen?)
	end
	
	it "should send an email to report the failure" do
		client.headers["accept"] = "text/plain"
		
		expect{client.get "/blow?source=test"}.to raise_exception(StandardError, message: be =~ /Arrrh/)
		
		last_mail = Mail::TestMailer.deliveries.last
		
		expect(last_mail.to_s).to be(:include?, "GET")
		expect(last_mail.to_s).to be(:include?, "/blow")
		expect(last_mail.to_s).to be(:include?, "request.ip")
		expect(last_mail.to_s).to be(:include?, "request.query_parameters.source")
		expect(last_mail.to_s).to be(:include?, "header[")
		expect(last_mail.to_s).to be(:include?, "TharSheBlows")
	end
	
	it "reports exceptions without backtraces and their causes" do
		cause = Object.new
		cause.define_singleton_method(:to_s){"Inner failure"}
		cause.define_singleton_method(:cause){nil}
		
		exception = Object.new
		exception.define_singleton_method(:to_s){"Outer failure"}
		exception.define_singleton_method(:cause){cause}
		
		output = StringIO.new
		mailer = subject.new(Protocol::HTTP::Middleware::NotFound, delivery_method: nil)
		mailer.send(:generate_backtrace, output, exception)
		
		expect(output.string).to be(:include?, "Exception Object: Outer failure")
		expect(output.string).to be(:include?, "Caused by Object: Inner failure")
	end
	
	it "attaches buffered request bodies and environment state" do
		request = Utopia::Request["POST", "/submit", {}, ["Hello World!"]]
		mailer = subject.new(
			Protocol::HTTP::Middleware::NotFound,
			delivery_method: nil,
			dump_environment: true,
		)
		
		mail = mailer.send(:generate_mail, RuntimeError.new("Failure"), request)
		
		expect(mail.attachments["body.bin"].decoded).to be == "Hello World!"
		expect(mail.attachments["state.yaml"]).not.to be_nil
	end
	
	it "does not propagate delivery failures" do
		delivery_method = Class.new do
			def initialize(*)
			end
			
			def deliver!(mail)
				raise "Delivery failed"
			end
		end
		
		request = Utopia::Request["GET", "/"]
		mailer = subject.new(Protocol::HTTP::Middleware::NotFound, delivery_method: delivery_method)
		mailer.send(:send_notification, RuntimeError.new("Failure"), request)
		
		expect_console.to have_logged(
			severity: be == :warn,
			message: be == "Failed to deliver exception notification.",
			error: have_attributes(message: be == "Delivery failed"),
		)
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
