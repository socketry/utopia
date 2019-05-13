
prepend Actions

on 'events' do |request|
	upgrade = Async::WebSocket::Server::Rack.open(request.env) do |connection|
		connection.write({type: "test", data: "Hello World"})
	end
	
	respond?(upgrade) or fail!
end
