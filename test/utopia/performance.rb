# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2016-2025, by Samuel Williams.

require "benchmark/ips" if ENV["BENCHMARK"]
require "ruby-prof" if ENV["PROFILE"]
require "flamegraph" if ENV["FLAMEGRAPH"]
require "protocol/http/request"
require "utopia/application"

describe "Utopia Performance" do
	let(:app) {Utopia::Application.load(File.join(__dir__, ".performance/config/application.rb"))}
	
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
				yield 2000
			end
			
			#result.eliminate_methods!([/^((?!Utopia|Trenni).)*$/])
			printer = RubyProf::FlatPrinter.new(result)
			printer.print($stderr, min_percent: 1.0)
			
			printer = RubyProf::GraphHtmlPrinter.new(result)
			filename = name.gsub("/", "_") + ".html"
			File.open(filename, "w") do |file|
				printer.print(file)
			end
		end
	elsif defined? Flamegraph
		def benchmark(name)
			filename = name.gsub("/", "_") + ".html"
			Flamegraph.generate(filename) do
				yield 1
			end
		end
	else
		def benchmark(name)
			yield 1
		end
	end
	
	it "should be fast to access basic page" do
		request = Protocol::HTTP::Request["GET", "/welcome/index"]
		response = app.call(request)
		
		expect(response.status).to be == 200
		
		benchmark("/welcome/index") do |i|
			i.times{app.call(request)}
		end
	end
	
	it "should be fast to invoke a controller" do
		request = Protocol::HTTP::Request["GET", "/api/fetch"]
		request.headers["accept"] = "application/json"
		response = app.call(request)
		
		expect(response.status).to be == 200
		
		benchmark("/api/fetch") do |i|
			i.times{app.call(request)}
		end
	end
end
