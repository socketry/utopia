# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2015-2025, by Samuel Williams.

require "a_rack_application"

require "utopia/exceptions"
require "utopia/controller"

describe Utopia::Exceptions::Handler do
	include_context ARackApplication, File.expand_path("handler.ru", __dir__)
	
	it "should successfully call the controller method" do
		# This request will raise an exception, and then redirect to the /exception url which will fail again, and cause a fatal error.
		get "/blow?fatal=true"
		
		expect(last_response.status).to be == 500
		expect(last_response.headers["content-type"]).to be == "text/plain"
		expect(last_response.body).to be(:include?, "fatal error")
	end
	
	it "should fail with a 500 error" do
		get "/blow"
		
		expect(last_response.status).to be == 500
		expect(last_response.body).to be(:include?, "Error Will Robertson")
	end
end
