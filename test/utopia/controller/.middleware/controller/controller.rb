# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2015-2023, by Samuel Williams.

prepend Actions

on 'flat' do
	respond! Utopia::Response[200, {}, ["flat"]]
end

on '**/hello-world' do
	respond! Utopia::Response[200, {}, [@hello_world]]
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

on 'goto' do
	goto! 'some path'
end

on 'index' do
	respond! Utopia::Response[200, {}, ['Hello World']]
end
