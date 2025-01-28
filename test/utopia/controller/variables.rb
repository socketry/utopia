# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2016-2025, by Samuel Williams.

require "utopia/controller/variables"

class TestController
	attr_accessor :x, :y, :z
	
	def copy_instance_variables(from)
		from.instance_variables.each do |name|
			self.instance_variable_set(name, from.instance_variable_get(name))
		end
	end
end

describe Utopia::Controller::Variables do
	let(:variables) {subject.new}
	
	let(:a) {TestController.new.tap{|controller| controller.x = 10}}
	let(:b) {TestController.new.tap{|controller| controller.y = 20}}
	let(:c) {TestController.new.tap{|controller| controller.z = 30}}
	
	it "should fetch a key" do
		variables << a
		
		expect(variables[:x]).to be == 10
	end
	
	it "should give a default when key is not found" do
		variables << a
		
		expect(variables.fetch(:y, :default)).to be == :default
		expect(variables.fetch(:y){:default}).to be == :default
	end
	
	it "should convert to hash" do
		variables << a << b
		
		expect(variables.to_hash).to be == {x: 10, y: 20}
	end
end
