# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2015-2023, by Samuel Williams.

prepend Actions

on 'foobar' do
	respond! Utopia::Response[200, {}, ["Foobar"]]
end
