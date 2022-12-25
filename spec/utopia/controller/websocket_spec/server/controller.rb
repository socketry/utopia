# frozen_string_literal: true

prepend Actions

on 'events' do |request|
	upgrade = Async::WebSocket::Adapters::Rack.open(request.env) do |connection|
		connection.write({type: "test", data: "Hello World"}.to_json)
	end
	
	respond?(upgrade) or fail!
end
