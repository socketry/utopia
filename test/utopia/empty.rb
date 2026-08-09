# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2021-2025, by Samuel Williams.

require "sus/fixtures/protocol/http/middleware_context"
require "utopia/application"
require "utopia/content"

describe Utopia::Content do
	include Sus::Fixtures::Protocol::HTTP::MiddlewareContext
	
	let(:middleware) {Utopia::Application.default}
	
	it "should report 404 missing" do
		client.get "/index"
		
		expect(last_response.status).to be == 404
	end
end
