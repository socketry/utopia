# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2016-2026, by Samuel Williams.

require "utopia/controller"

describe Utopia::Controller::Actions::Action do
	let(:action) {subject.new}
	
	it "can be a hash key" do
		expect(action).to be == action
		expect(action.hash).to be == action.hash
		expect(action).to be_equal(action)
	end
	
	it "compares callbacks and options" do
		callback = proc{}
		left = subject.new({name: "test"}, &callback)
		right = subject.new({name: "test"}, &callback)
		
		expect(left.eql?(right)).to be == true
		expect(left.hash).to be == right.hash
	end
	
	it "describes configured actions" do
		callback = proc{}
		configured = subject.new({name: "test"}, &callback)
		
		expect(action.inspect).to be == "<action {}>"
		expect(configured.inspect).to be(:include?, callback.source_location.to_s)
		expect(configured.inspect).to be(:include?, configured.options.inspect)
	end
	
	it "should resolve callbacks" do
		specific_action = action.define(["a", "b", "c"]){puts "specific_action"}
		indirect_action = action.define(["**"]){puts "indirect_action"}
		indirect_named_action = action.define(["**", "r"]){puts "indirect_named_action"}
		
		expect(specific_action).not.to be == indirect_action
		expect(indirect_action).not.to be == indirect_named_action
		
		expect(action.matching(["a", "b", "c"])).to be == [indirect_action, specific_action]
		expect(action.matching(["q"])).to be == [indirect_action]
		
		expect(action.matching(["q", "r"])).to be == [indirect_action, indirect_named_action]
		expect(action.matching(["q", "r", "s"])).to be == [indirect_action]
	end
	
	it "should be greedy matching" do
		greedy_action = action.define(["**", "r"]){puts "greedy_action"}
		
		expect(action.matching(["g", "r"])).to be(:include?, greedy_action)
		expect(action.matching(["r"])).to be(:include?, greedy_action)
	end
	
	it "should match patterns" do
		variable_action = action.define(["*", "summary", "*"]){puts "variable_action"}
		
		expect(action.matching(["10", "summary", "20"])).to be(:include?, variable_action)
	end
end

describe Utopia::Controller::Actions do
	it "dispatches the fallback action" do
		controller_class = Class.new(Utopia::Controller::Base) do
			prepend Utopia::Controller::Actions
			
			otherwise do |request, path|
				succeed!(path.to_s)
			end
		end
		
		controller = controller_class.new
		request = Utopia::Request["GET", "/missing"]
		result = controller.process!(request, Utopia::Path["missing"])
		
		expect(result).to be_a(Utopia::Controller::Result)
		expect(result.value).to be == "missing"
	end
end
