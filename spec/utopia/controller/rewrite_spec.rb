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
			
			on 'edit' do |request, path|
				@edit = true
			end
			
			attr :edit
			
			rewrite.extract_prefix user_id: Integer, summary: 'summary', order_id: Integer
			
			attr :user_id
			attr :order_id
			
			def self.uri_path
				Utopia::Path['/']
			end
		end
		
		let(:controller) {TestController.new}
		
		def mock_request(*args)
			request = Rack::Request.new(Rack::MockRequest.env_for(*args))
			return request, Utopia::Path[request.path_info]
		end
		
		it "should match path prefix and extract parameters" do
			request, path, variables = mock_request("/10/summary/20/edit")
			relative_path = path - controller.class.uri_path
			
			controller.process!(request, relative_path)
			
			expect(controller.user_id).to be == 10
			expect(controller.order_id).to be == 20
			expect(controller.edit).to be true
		end
	end
end
