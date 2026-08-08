# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2026, by Samuel Williams.

require "json"
require "utopia/controller"
require_relative "../protocol_application"

describe Utopia::Controller do
	include ProtocolApplication
	
	let(:app) do
		root = File.expand_path(".parameters", __dir__)
		
		Utopia::Application.build do
			use Utopia::Controller, root: root
		end
	end
	
	cases_path = File.expand_path("parameters/cases/*.json", __dir__)
	
	Dir.glob(cases_path).sort.each do |path|
		name = File.basename(path, ".json")
		test_case = JSON.parse(File.read(path))
		
		it "handles parameter content", unique: name do
			request_data = test_case.fetch("request")
			response_data = test_case.fetch("response")
			
			if body_path = request_data["body_path"]
				request_body = File.binread(File.join(File.dirname(path), body_path))
			else
				request_body = request_data["body"]
			end
			
			request(
				request_data.fetch("method"),
				request_data.fetch("path"),
				request_data.fetch("headers"),
				request_body
			)
			
			expect(last_response.status).to be == response_data.fetch("status")
			expect(last_response.headers["content-type"]).to be == "application/json"
			expect(JSON.parse(body)).to be == response_data.fetch("body")
		end
	end
end
