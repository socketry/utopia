# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2019-2025, by Samuel Williams.

require "rack/test"
require "utopia/controller"

require "async/websocket/client"
require "async/websocket/adapters/rack"

require "sus/fixtures/async/http/server_context"

require "async/http/client"
require "async/http/endpoint"

describe Utopia::Controller do
	include Sus::Fixtures::Async::HTTP::ServerContext
	
	with Async::WebSocket::Client do
		let(:rack_app) {Rack::Builder.parse_file(File.expand_path("websocket.ru", __dir__))}
		let(:app) {::Protocol::Rack::Adapter.new(rack_app)}
		
		it "fails for normal requests" do
			response = client.get "/server/events"
			expect(response.status).to be == 400
		ensure
			response&.finish
		end
		
		it "can connect to websocket" do
			mock(client_endpoint) do |mock|
				mock.replace(:path) {"/server/events"}
			end
			
			Async::WebSocket::Client.connect(client_endpoint) do |connection|
				message = connection.read
				expect(JSON.parse(message, symbolize_names: true)).to be == {type: "test", data: "Hello World"}
			end
		end
	end
end
