# frozen_string_literal: true

require 'benchmark/ips'

STRING_HASH = { "foo" => "bar" }
SYMBOL_HASH = { :foo => "bar"  }

Benchmark.ips do |x|
	x.report("string") { STRING_HASH["foo"] }
	x.report("symbol") { SYMBOL_HASH[:foo]  }
	x.report("symbol-from-string") { SYMBOL_HASH["foo".to_sym]  }
	
	x.compare!
end