# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2018-2023, by Samuel Williams.

prepend Respond, Actions

# Respond with json:
respond.with_json

# This method should return HTML, even thought this controller responds with JSON.
on 'hello-world' do
	respond! Utopia::Response[200, {"content-type" => "text/html"}, ["<p>Hello World</p>"]]
end
