# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2021-2025, by Samuel Williams.

require "rack/test"
require "utopia/content"

describe Utopia::Content do
	include Rack::Test::Methods
	
	let(:app) {Rack::Builder.parse_file(File.expand_path("empty.ru", __dir__))}
	
	it "should report 404 missing" do
		get "/index"
		
		expect(last_response.status).to be == 404
	end
end
