# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2017-2020, by Samuel Williams.

require 'benchmark/ips'

class A
end

class B
	def self.do
	end
end

class C
	def self.do
	end
end

Benchmark.ips do |x|
	x.report("responds_to? (nothing)") do |times|
		while (times -= 1) >= 0
			A.do if A.respond_to?(:do)
		end
	end
	
	x.report("B (empty method)") do |times|
		while (times -= 1) >= 0
			B.do
		end
	end
	
	x.report("responds_to? (empty method)") do |times|
		while (times -= 1) >= 0
			C.do if C.respond_to?(:do)
		end
	end
	
	x.compare!
end
