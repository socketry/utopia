#!/usr/bin/env rspec
# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2016-2020, by Samuel Williams.

require 'utopia/controller/variables'

RSpec.describe Utopia::Controller::Variables do
	class TestController
		attr_accessor :x, :y, :z
		
		def copy_instance_variables(from)
			from.instance_variables.each do |name|
				self.instance_variable_set(name, from.instance_variable_get(name))
			end
		end
	end
	
	let(:a) {TestController.new.tap{|controller| controller.x = 10}}
	let(:b) {TestController.new.tap{|controller| controller.y = 20}}
	let(:c) {TestController.new.tap{|controller| controller.z = 30}}
	
	it "should fetch a key" do
		subject << a
		
		expect(subject[:x]).to be == 10
	end
	
	it "should give a default when key is not found" do
		subject << a
		
		expect(subject.fetch(:y, :default)).to be == :default
		expect(subject.fetch(:y){:default}).to be == :default
	end
	
	it "should convert to hash" do
		subject << a << b
		
		expect(subject.to_hash).to be == {x: 10, y: 20}
	end
end
