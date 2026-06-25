# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2015-2025, by Samuel Williams.

require "protocol/http/request"
require "utopia/controller"
require "utopia/request"

describe Utopia::Controller do
	class TestController < Utopia::Controller::Base
		prepend Utopia::Controller::Rewrite, Utopia::Controller::Actions
		
		on "edit" do |request, path|
			@edit = true
		end
		
		attr :edit
		
		rewrite.extract_prefix user_id: Integer, summary: "summary", order_id: Integer
		
		attr :user_id
		attr :order_id
		
		rewrite.extract_prefix fail: "fail" do
			fail! 444
		end
		
		def self.uri_path
			Utopia::Path["/"]
		end
	end
	
	let(:controller) {TestController.new}
	
	def mock_request(path)
		request = Protocol::HTTP::Request["GET", path]
		return request, Utopia::Path[request.path_info]
	end
	
	it "should match path prefix and extract parameters" do
		request, path = mock_request("/10/summary/20/edit")
		relative_path = path - controller.class.uri_path
		
		controller.process!(request, relative_path)
		
		expect(controller.user_id).to be == 10
		expect(controller.order_id).to be == 20
		expect(controller.edit).to be == true
	end
	
	it "should allow rewrite to fail request" do
		request, path = mock_request("/fail")
		relative_path = path - controller.class.uri_path
		
		response = controller.process!(request, relative_path)
		
		expect(response.status).to be == 444
	end
end
