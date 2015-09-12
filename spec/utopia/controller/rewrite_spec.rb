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

require 'rack/mock'

require 'utopia/controller'

module Utopia::Controller::RewriteSpec
	describe Utopia::Controller do
		class TestController < Utopia::Controller::Base
			prepend Utopia::Controller::Rewrite
			
			on 'test' do |request, path|
				@test = true
			end
			
			rewrite.sub /apples/, 'oranges'
			
			rewrite.match /^(?<id>\d+)(\/|$)/ do |match_data|
				@id = Integer(match_data[:id])
				
				match_data.post_match
			end
			
			attr :id
			
			def self.uri_path
				Utopia::Path['/']
			end
		end
		
		it "should generate an invocation" do
			controller = Utopia::Controller::Base.new
		end
		
		def mock_request(*args)
			Rack::Request.new(Rack::MockRequest.env_for(*args))
		end
		
		let(:controller) {TestController.new}
		
		it "should substitude path components" do
			expect(controller.rewrite("/apples/juice")).to be == "/oranges/juice"
		end
	end
end
