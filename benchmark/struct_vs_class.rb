# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2016-2025, by Samuel Williams.

require "benchmark/ips"

# This benchmark compares accessing an instance variable vs accessing a struct member (via a function). The actual method dispatch is about 25% slower.

puts "Ruby #{RUBY_VERSION} at #{Time.now}"

ItemsStruct = Struct.new(:items) do
	def initialize
		super []
	end
	
	def push_me_pull_you(value = :x)
		items = self.items
		
		items << value
		items.pop
	end
	
	def empty?
		self.items.empty?
	end
end

class ItemsClass
	def initialize
		@items = []
	end
	
	def push_me_pull_you(value = :x)
		items = @items
		
		items << value
		items.pop
	end
	
	def empty?
		@items.empty?
	end
end

# There IS a measuarble difference:
Benchmark.ips do |x|
	x.report("Struct#empty?") do |times|
		i = 0
		instance = ItemsStruct.new
		
		while i < times
			break unless instance.empty?
			i += 1
		end
	end
	
	x.report("Class#empty?") do |times|
		i = 0
		instance = ItemsClass.new
		
		while i < times
			break unless instance.empty?
			i += 1
		end
	end
	
	x.compare!
end

# This shows that in the presence of additional work, the difference is neglegible.
Benchmark.ips do |x|
	x.report("Struct#push_me_pull_you") do |times|
		i = 0
		a = A.new
		
		while i < times
			a.push_me_pull_you(i)
			i += 1
		end
	end
	
	x.report("Class#push_me_pull_you") do |times|
		i = 0
		b = B.new
		
		while i < times
			b.push_me_pull_you(i)
			i += 1
		end
	end
	
	x.compare!
end
