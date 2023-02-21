# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2016-2023, by Samuel Williams.

prepend Respond, Actions
respond.with_json

on 'fetch' do
	succeed! content: [1, 2, 3]
end
