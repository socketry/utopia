# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2021-2025, by Samuel Williams.

require "utopia/content"
require_relative "protocol_application"

describe Utopia::Content do
	include ProtocolApplication
	
	let(:app) {Utopia::Application.default}
	
	it "should report 404 missing" do
		get "/index"
		
		expect(last_response.status).to be == 404
	end
end
