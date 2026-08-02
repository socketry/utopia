# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2019-2026, by Samuel Williams.

require "utopia/controller"
require "utopia/application"

require "async/websocket/client"
require "async/websocket/adapters/http"

require "sus/fixtures/async/http/server_context"

require "async/http/client"
require "async/http/endpoint"

describe Utopia::Controller do
	include Sus::Fixtures::Async::HTTP::ServerContext
	
	with Async::WebSocket::Client do
		let(:app) do
			root = File.expand_path(".websocket", __dir__)
			
			Utopia::Application.build do
				use Utopia::Controller, root: root
			end
		end
		
		it "fails for normal requests" do
			response = client.get "/server/events"
			expect(response.status).to be == 400
		ensure
			response&.finish
		end
		
		it "can connect to websocket" do
			mock(client_endpoint) do |mock|
				mock.replace(:path){"/server/events"}
			end
			
			Async::WebSocket::Client.connect(client_endpoint) do |connection|
				message = connection.read
				expect(JSON.parse(message, symbolize_names: true)).to be == {type: "test", data: "Hello World"}
			end
		end
	end
end
