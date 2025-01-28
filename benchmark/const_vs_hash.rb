# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2017-2025, by Samuel Williams.

require "benchmark/ips"

module Foo
	class Bar
	end
end


THINGS = {
	"Bar" => Foo::Bar
}

Benchmark.ips do |x|
	x.report("const_get('Bar')") do |i|
		while (i -= 1) > 0
			Foo.const_get("Bar")
		end
	end

	x.report("const_get(:Bar)") do |i|
		while (i -= 1) > 0
			Foo.const_get(:Bar)
		end
	end

	x.report("Hash\#[]") do |i|
		while (i -= 1) > 0
			THINGS["Bar"]
		end
	end
	
	x.compare!
end
