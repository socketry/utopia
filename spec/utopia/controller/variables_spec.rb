#!/usr/bin/env rspec
# frozen_string_literal: true

# Copyright, 2012, by Samuel G. D. Williams. <http://www.codeotaku.com>
# 
# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:
# 
# The above copyright notice and this permission notice shall be included in
# all copies or substantial portions of the Software.
# 
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
# THE SOFTWARE.

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
