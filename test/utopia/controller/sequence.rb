# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2015-2023, by Samuel Williams.

require 'rack/mock'
require 'rack/test'
require 'utopia/controller'

class TestController < Utopia::Controller::Base
	prepend Utopia::Controller::Actions
	
	on 'success' do
		succeed!
	end
	
	on :failure do
		fail! 400
	end
	
	on :variable do |request, path|
		@variable = :value
	end
end

class TestIndirectController < Utopia::Controller::Base
	prepend Utopia::Controller::Actions
	
	def initialize
		@sequence = String.new
	end
	
	on('user/update') do
		@sequence << 'A'
	end
	
	on('**/comment/post') do
		@sequence << 'B'
	end
	
	on('comment/delete') do
		@sequence << 'C'
	end
	
	on('**/comment/delete') do
		@sequence << 'D'
	end
	
	on('**') do
		@sequence << 'E'
	end
	
	on('*') do
		@sequence << 'F'
	end
end

describe Utopia::Controller do
	let(:variables) {Utopia::Controller::Variables.new}
	
	it "should call controller methods" do
		request = Rack::Request.new(Utopia::VARIABLES_KEY => variables)
		controller = TestController.new
		variables << controller
	
		result = controller.process!(request, Utopia::Path["success"])
		expect(result).to be == [200, {}, []]
	
		result = controller.process!(request, Utopia::Path["foo/bar/failure"])
		expect(result).to be == [400, {}, ["Bad Request"]]
	
		result = controller.process!(request, Utopia::Path["variable"])
		expect(result).to be == nil
		expect(variables.to_hash).to be == {:variable => :value}
	end
	
	it "should call direct controller methods" do
		request = Rack::Request.new(Utopia::VARIABLES_KEY => variables)
		controller = TestIndirectController.new
		variables << controller
		
		controller.process!(request, Utopia::Path["user/update"])
		expect(variables['sequence']).to be == 'EA'
	end
	
	it "should call indirect controller methods" do
		request = Rack::Request.new(Utopia::VARIABLES_KEY => variables)
		controller = TestIndirectController.new
		variables << controller
		
		result = controller.process!(request, Utopia::Path["foo/comment/post"])
		expect(result).to be_nil
		expect(variables['sequence']).to be == 'EB'
	end
	
	it "should call multiple indirect controller methods in order" do
		request = Rack::Request.new(Utopia::VARIABLES_KEY => variables)
		controller = TestIndirectController.new
		variables << controller
		
		result = controller.process!(request, Utopia::Path["comment/delete"])
		expect(result).to be_nil
		expect(variables['sequence']).to be == 'EDC'
	end
	
	it "should match single patterns" do
		request = Rack::Request.new(Utopia::VARIABLES_KEY => variables)
		controller = TestIndirectController.new
		variables << controller
		
		result = controller.process!(request, Utopia::Path["foo"])
		expect(result).to be_nil
		expect(variables['sequence']).to be == 'EF'
	end
end
