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
	APP = lambda {|env| [404, [], []]}
	
	class TestController < Utopia::Middleware::Controller::Base
		def direct?(path)
			true
		end
		
		def on_success(path, request)
			success!
		end
		
		def on_failure(path, request)
			fail!
		end
		
		def on_variable(path, request)
			@variable = :value
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
			controller = TestController.new(middleware)
		
			result = controller.process!(Utopia::Path["/success"], request)
			expect(result).to be == [200, {}, []]
		
			result = controller.process!(Utopia::Path["/failure"], request)
			expect(result).to be == [400, {}, ["Bad Request"]]
		
			result = controller.process!(Utopia::Path["/variable"], request)
			expect(variables.to_hash).to be == {"variable"=>:value}
		end
	end
end
