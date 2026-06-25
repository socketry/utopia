# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2026, by Samuel Williams.

require "protocol/http/request"
require "utopia/context"
require "utopia/request"

describe Utopia::Context do
	let(:request) {Protocol::HTTP::Request["GET", "/hello"]}
	
	after do
		subject.clear
	end
	
	it "stores request state directly in fiber storage" do
		subject.request = request
		subject.request_path = request.path_info
		
		expect(subject.request).to be_equal(request)
		expect(subject.request_path).to be == "/hello"
	end
	
	it "scopes temporary assignments" do
		subject.current_locale = "en"
		
		subject.with(current_locale: "ja") do
			expect(subject.current_locale).to be == "ja"
		end
		
		expect(subject.current_locale).to be == "en"
	end
	
	it "is inherited by nested fibers" do
		subject.session = Object.new
		
		fiber = Fiber.new do
			subject.session
		end
		
		expect(fiber.resume).to be_equal(subject.session)
	end
end
