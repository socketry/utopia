# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2015-2026, by Samuel Williams.

require "sus/fixtures/protocol/http/middleware_context"
require "utopia/application"
require "utopia/exceptions"
require "utopia/controller"

describe Utopia::Exceptions::Handler do
	include Sus::Fixtures::Protocol::HTTP::MiddlewareContext
	
	let(:middleware) do
		root = File.expand_path(".handler", __dir__)
		
		Utopia::Application.build do
			use Utopia::Exceptions::Handler, "/exception"
			use Utopia::Controller, root: root
		end
	end
	
	it "should successfully call the controller method" do
		# This request will raise an exception, and then redirect to the /exception url which will fail again, and cause a fatal error.
		client.get "/blow?fatal=true"
		
		expect(last_response.status).to be == 500
		expect(last_response.headers["content-type"]).to be == "text/plain"
		expect(last_response.read).to be(:include?, "error")
	end
	
	it "should fail with a 500 error" do
		client.get "/blow"
		
		expect(last_response.status).to be == 500
		expect(last_response.read).to be(:include?, "Error: Arrrh!")
	end
	
	it "handles application syntax errors" do
		client.get "/syntax-error"
		
		expect(last_response.status).to be == 500
		expect(last_response.read).to be(:include?, "Invalid application syntax!")
	end
	
	it "does not handle process exceptions" do
		expect{client.get "/interrupt"}.to raise_exception(Interrupt, message: be =~ /Application interrupted/)
	end
end
