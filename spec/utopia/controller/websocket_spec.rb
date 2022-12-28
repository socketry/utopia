#!/usr/bin/env rspec
# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2019-2022, by Samuel Williams.

require 'rack/test'
require 'utopia/controller'

require 'async/websocket/client'
require 'async/websocket/adapters/rack'

require 'falcon/server'

require 'async/http/client'
require 'async/http/endpoint'

RSpec.describe Utopia::Controller do
	context Async::WebSocket::Client do
		include Rack::Test::Methods
		include_context Async::RSpec::Reactor
		
		let(:app) {Rack::Builder.parse_file(File.expand_path('websocket_spec.ru', __dir__))}
		
		before do
			@endpoint = Async::HTTP::Endpoint.parse("http://localhost:7050/server/events")
			@server = Falcon::Server.new(Falcon::Server.middleware(app), @endpoint)
			
			@server_task = reactor.async do
				@server.run
			end
		end
		
		let(:client) {Async::HTTP::Client.new(@endpoint)}
		
		after do
			@server_task.stop
		end
		
		it "fails for normal requests" do
			get "/server/events"
			
			expect(last_response.status).to be == 400
		end
		
		it "can connect to websocket" do
			Async::WebSocket::Client.connect(@endpoint) do |connection|
				message = connection.read
				expect(JSON.parse(message, symbolize_names: true)).to be == {type: "test", data: "Hello World"}
			end
		end
	end
end
