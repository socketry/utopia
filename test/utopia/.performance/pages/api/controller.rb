# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2016-2026, by Samuel Williams.

prepend Respond, Actions
responds.with_json

on 'fetch' do
	succeed! [1, 2, 3]
end
