# frozen_string_literal: true

# Copyright, 2017, by Samuel G. D. Williams. <http://www.codeotaku.com>
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

require 'utopia/content/tags'
require 'utopia/content/document'

require 'mock_node'

RSpec.describe Utopia::Content::Tags do
	let(:document) {Utopia::Content::Document.new(nil, {})}
	
	describe '<utopia:environment>' do
		let(:node) do
			MockNode.new('utopia' => subject) do |document, state|
				document.tag("utopia:environment", only: 'test') do
					document.text("Hello World")
				end
				
				document.tag("utopia:environment", only: 'production') do
					document.text("Goodbye World")
				end
			end
		end
		
		it "it should render correct content for test" do
			document[:environment] = "test"
			
			result = document.render_node(node)
			
			expect(result).to be == 'Hello World'
		end
		
		it "it should render correct content for production" do
			document[:environment] = "production"
			
			result = document.render_node(node)
			
			expect(result).to be == 'Goodbye World'
		end
	end
	
	describe '<utopia:node>' do
		let(:node) do
			MockNode.new('utopia' => subject) do |document, state|
				document.tag("utopia:node", path: 'test')
			end
		end
		
		let(:test_node) do
			MockNode.new do |document, state|
				document.text("Test Node")
			end
		end
		
		it "it should render correct content for test" do
			expect(document).to receive(:lookup_node).with('test').and_return(test_node)
			
			result = document.render_node(node)
			
			expect(result).to be == 'Test Node'
		end
	end
end
