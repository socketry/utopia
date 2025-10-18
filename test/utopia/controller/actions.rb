# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2016-2025, by Samuel Williams.

require "utopia/controller"

describe Utopia::Controller::Actions::Action do
	let(:action) {subject.new}
	
	it "can be a hash key" do
		expect(action).to be == action
		expect(action.hash).to be == action.hash
		expect(action).to be_equal(action)
	end
	
	it "should resolve callbacks" do
		specific_action = action.define(["a", "b", "c"]) {puts "specific_action"}
		indirect_action = action.define(["**"]) {puts "indirect_action"}
		indirect_named_action = action.define(["**", "r"]) {puts "indirect_named_action"}
		
		expect(specific_action).not.to be == indirect_action
		expect(indirect_action).not.to be == indirect_named_action
		
		expect(action.matching(["a", "b", "c"])).to be == [indirect_action, specific_action]
		expect(action.matching(["q"])).to be == [indirect_action]
		
		expect(action.matching(["q", "r"])).to be == [indirect_action, indirect_named_action]
		expect(action.matching(["q", "r", "s"])).to be == [indirect_action]
	end
	
	it "should be greedy matching" do
		greedy_action = action.define(["**", "r"]) {puts "greedy_action"}
		
		expect(action.matching(["g", "r"])).to be(:include?, greedy_action)
		expect(action.matching(["r"])).to be(:include?, greedy_action)
	end
	
	it "should match patterns" do
		variable_action = action.define(["*", "summary", "*"]) {puts "variable_action"}
		
		expect(action.matching(["10", "summary", "20"])).to be(:include?, variable_action)
	end
end
