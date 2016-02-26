# Copyright, 2016, by Samuel G. D. Williams. <http://www.codeotaku.com>
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

require_relative 'rack_helper'

require 'benchmark/ips' if ENV['BENCHMARK']
require 'ruby-prof' if ENV['PROFILE']

RSpec.describe "Utopia Performance" do
	include_context "rack app", "benchmark_spec/config.ru"
	
	if defined? Benchmark
		def benchmark(name = nil)
			Benchmark.ips do |benchmark|
				benchmark.report(name) do |i|
					yield i
				end
				
				benchmark.compare!
			end
		end
	elsif defined? RubyProf
		def benchmark(name)
			result = RubyProf.profile do
				yield 1000
			end
			
			# result.eliminate_methods!([/Integer/, /Rack::Test/])
			printer = RubyProf::FlatPrinter.new(result)
			printer.print($stderr, min_percent: 1.0)
		end
	else
		def benchmark(name)
			yield 1
		end
	end
	
	it "should be fast to access basic page" do
		env = Rack::MockRequest.env_for("/welcome/index")
		status, headers, response = app.call(env)
		
		expect(status).to be == 200
		
		benchmark("/welcome/index") do |i|
			i.times { app.call(env) }
		end
	end
	
	it "should be fast to invoke a controller" do
		env = Rack::MockRequest.env_for("/api/fetch")
		status, headers, response = app.call(env)
		
		expect(status).to be == 200
		
		benchmark("/api/fetch") do |i|
			i.times { app.call(env) }
		end
	end
end
