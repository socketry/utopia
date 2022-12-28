# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2019-2022, by Samuel Williams.

prepend Actions

on 'events' do |request|
	upgrade = Async::WebSocket::Adapters::Rack.open(request.env) do |connection|
		connection.write({type: "test", data: "Hello World"}.to_json)
	end
	
	respond?(upgrade) or fail!
end
