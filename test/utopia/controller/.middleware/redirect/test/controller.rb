# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2015-2023, by Samuel Williams.

prepend Actions

on 'bar' do |request, path|
	# puts "bar: #{URI_PATH.inspect}"
	
	succeed!
end
