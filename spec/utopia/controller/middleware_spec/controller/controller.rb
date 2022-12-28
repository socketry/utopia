# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2015-2022, by Samuel Williams.

prepend Actions

on 'flat' do
	succeed! content: "flat"
end

on '**/hello-world' do
	succeed! content: @hello_world
end

on '**' do
	@hello_world = "Hello World"
end

on 'ignore' do
	ignore!
end

on 'redirect' do
	redirect! 'bar'
end

on 'index' do
	succeed! content: 'Hello World'
end
