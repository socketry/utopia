#!/usr/bin/env rspec
# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2016-2020, by Samuel Williams.

require 'utopia/controller'

module Utopia::Controller::ActionsSpec
	describe Utopia::Controller::Actions::Action do
		it "can be a hash key" do
			expect(subject).to be == subject
			expect(subject.hash).to be == subject.hash
			expect(subject).to be_eql subject
		end
		
		it "should resolve callbacks" do
			specific_action = subject.define(['a', 'b', 'c']) {puts 'specific_action'}
			indirect_action = subject.define(['**']) {puts 'indirect_action'}
			indirect_named_action = subject.define(['**', 'r']) {puts 'indirect_named_action'}
			
			expect(specific_action).to_not be == indirect_action
			expect(indirect_action).to_not be == indirect_named_action
			
			expect(subject.matching(['a', 'b', 'c'])).to be == [indirect_action, specific_action]
			expect(subject.matching(['q'])).to be == [indirect_action]
			
			expect(subject.matching(['q', 'r'])).to be == [indirect_action, indirect_named_action]
			expect(subject.matching(['q', 'r', 's'])).to be == [indirect_action]
		end
		
		it "should be greedy matching" do
			greedy_action = subject.define(['**', 'r']) {puts 'greedy_action'}
			
			expect(subject.matching(['g', 'r'])).to be_include greedy_action
			expect(subject.matching(['r'])).to be_include greedy_action
		end
		
		it "should match patterns" do
			variable_action = subject.define(['*', 'summary', '*']) {puts 'variable_action'}
				
			expect(subject.matching(['10', 'summary', '20'])).to be_include variable_action
		end
	end
end
