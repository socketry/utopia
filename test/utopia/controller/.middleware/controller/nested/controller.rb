# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2015-2023, by Samuel Williams.

prepend Actions

on 'foobar' do
	succeed! content: "Foobar"
end
