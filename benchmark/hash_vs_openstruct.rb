# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2016-2025, by Samuel Williams.

require "benchmark/ips"
require "ostruct"

# This benchmark compares accessing an instance variable vs accessing a struct member (via a function). The actual method dispatch is about 25% slower.

puts "Ruby #{RUBY_VERSION} at #{Time.now}"

NAME = "Test Name"
EMAIL = "test@example.org"

test = nil

class ObjectHash
	def []= key, value
		instance_variable_set(key, value)
	end
	
	def [] key
		instance_variable_get(key)
	end
end

# There IS a measuarble difference:
Benchmark.ips do |x|
	x.report("Hash") do |i|
		i.times do
			p = {name: NAME, email: EMAIL}
			
			test = p[:name] + p[:email]
		end
	end
	
	x.report("OpenStruct") do |i|
		i.times do
			p = OpenStruct.new(name: NAME, email: EMAIL)
			
			test = p.name + p.email
		end
	end
	
	x.report("ObjectHash") do |i|
		i.times do
			o = ObjectHash.new
			o[:@name] = NAME
			o[:@email] = EMAIL
			
			test = o[:@name] + o[:@email]
		end
	end
	
	x.compare!
end
