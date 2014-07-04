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
require 'utopia/middleware/controller'

module Utopia::Middleware::ControllerSpec
	describe Utopia::Middleware::Controller::Action do
		it "should resolve callbacks" do
			actions = Utopia::Middleware::Controller::Action.new
			
			specific_action = actions.define(['a', 'b', 'c']) {puts 'specific_action'}
			indirect_action = actions.define(['**']) {puts 'indirect_action'}
			indirect_named_action = actions.define(['**', 'r']) {puts 'indirect_named_action'}
			
			expect(specific_action).to_not be == indirect_action
			expect(indirect_action).to_not be == indirect_named_action
			
			expect(actions.select(['a', 'b', 'c'])).to be_include(specific_action)
			expect(actions.select(['q'])).to be_include(indirect_action)
			
			expect(actions.select(['q', 'r'])).to be_include(indirect_named_action)
			expect(actions.select(['q', 'r', 's'])).to be == [indirect_action]
		end
	end
	
	APP = lambda {|env| [404, [], []]}
	
	class TestController < Utopia::Middleware::Controller::Base
		on 'success' do
			success!
		end
		
		on :failure do
			fail!
		end
		
		on :variable do |request, path|
			@variable = :value
		end
		
		def self.uri_path
			Utopia::Path["/"]
		end
	end
	
	class TestIndirectController < Utopia::Middleware::Controller::Base
		on('user/update') do
		end
		
		on('**/comment/post') do
		end
	end
	
	class MockControllerMiddleware
		attr :env
		
		def call(env)
			@env = env
		end
	end
	
	describe Utopia::Middleware::Controller do
		it "should call controller methods" do
			variables = Utopia::Middleware::Controller::Variables.new
			request = Rack::Request.new("utopia.controller" => variables)
			middleware = MockControllerMiddleware.new
			controller = TestController.new
		
			result = controller.process!(request, Utopia::Path["/success"])
			expect(result).to be == [200, {}, []]
		
			result = controller.process!(request, Utopia::Path["/failure"])
			expect(result).to be == [400, {}, ["Bad Request"]]
		
			result = controller.process!(request, Utopia::Path["/variable"])
			expect(variables.to_hash).to be == {"variable"=>:value}
		end
	end
end
