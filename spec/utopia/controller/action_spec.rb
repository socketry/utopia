#!/usr/bin/env rspec

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

require 'utopia/controller'

module Utopia::Controller::ActionSpec
	describe Utopia::Controller::Action do
		it "should resolve callbacks" do
			actions = Utopia::Controller::Action.new
			
			specific_action = actions.define(['a', 'b', 'c']) {puts 'specific_action'}
			indirect_action = actions.define(['**']) {puts 'indirect_action'}
			indirect_named_action = actions.define(['**', 'r']) {puts 'indirect_named_action'}
			
			expect(specific_action).to_not be == indirect_action
			expect(indirect_action).to_not be == indirect_named_action
			
			expect(actions.select(['a', 'b', 'c'])).to be == [indirect_action, specific_action]
			expect(actions.select(['q'])).to be == [indirect_action]
			
			expect(actions.select(['q', 'r'])).to be == [indirect_action, indirect_named_action]
			expect(actions.select(['q', 'r', 's'])).to be == [indirect_action]
		end
		
		it "should be greedy matching" do
			actions = Utopia::Controller::Action.new
			
			greedy_action = actions.define(['**', 'r']) {puts 'greedy_action'}
			
			expect(actions.select(['g', 'r'])).to be_include greedy_action
			expect(actions.select(['r'])).to be_include greedy_action
		end
		
		it "should match patterns" do
			actions = Utopia::Controller::Action.new
			
			variable_action = actions.define(['*', 'summary', '*']) {puts 'variable_action'}
				
			expect(actions.select(['10', 'summary', '20'])).to be_include variable_action
		end
	end
end
