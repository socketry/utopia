# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2015-2025, by Samuel Williams.

require "utopia/exceptions"
require "utopia/controller"
require_relative "../protocol_application"

describe Utopia::Exceptions::Handler do
	include ProtocolApplication
	
	let(:app) do
		root = File.expand_path(".handler", __dir__)
		
		Utopia::Application.build do
			use Utopia::Exceptions::Handler, "/exception"
			use Utopia::Controller, root: root
		end
	end
	
	it "should successfully call the controller method" do
		# This request will raise an exception, and then redirect to the /exception url which will fail again, and cause a fatal error.
		get "/blow?fatal=true"
		
		expect(last_response.status).to be == 500
		expect(last_response.headers["content-type"]).to be == "text/plain"
		expect(body).to be(:include?, "error")
	end
	
	it "should fail with a 500 error" do
		get "/blow"
		
		expect(last_response.status).to be == 500
		expect(body).to be(:include?, "Error Will Robertson")
	end
end
