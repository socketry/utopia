# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2017-2022, by Samuel Williams.

require 'utopia/content/tags'
require 'utopia/content/document'

require 'mock_node'

RSpec.describe Utopia::Content::Tags do
	let(:document) {Utopia::Content::Document.new(nil, {})}
	
	describe '<utopia:environment>' do
		let(:node) do
			MockNode.new('utopia' => subject) do |document, state|
				document.tag("utopia:environment", only: 'testing') do
					document.text("Hello World")
				end
				
				document.tag("utopia:environment", only: 'production') do
					document.text("Goodbye World")
				end
			end
		end
		
		it "it should render correct content for test" do
			document[:variant] = "testing"
			
			result = document.render_node(node)
			
			expect(result).to be == 'Hello World'
		end
		
		it "it should render correct content for production" do
			document[:variant] = "production"
			
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
