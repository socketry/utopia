# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2019-2023, by Samuel Williams.

prepend Actions

on 'events' do |request|
	upgrade = Async::WebSocket::Adapters::HTTP.open(request) do |connection|
		connection.write({type: "test", data: "Hello World"}.to_json)
	end
	
	respond?(upgrade) or fail!
end
