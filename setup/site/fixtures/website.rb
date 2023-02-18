# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2016-2023, by Samuel Williams.

require 'rack/test'
require 'sus/fixtures/async/http'
require 'protocol/rack'

AWebsite = Sus::Shared("a website") do
	include Rack::Test::Methods
	
	let(:rackup_path) {File.expand_path('../config.ru', __dir__)}
	let(:rackup_directory) {File.dirname(rackup_path)}
	
	let(:app) {Rack::Builder.parse_file(rackup_path)}
end

AValidPage = Sus::Shared("a valid page") do |path|
	it "can access #{path}" do
		get path
		
		while last_response.redirect?
			follow_redirect!
		end
		
		expect(last_response.status).to be == 200
	end
end

AServer = Sus::Shared("a server") do
	include Sus::Fixtures::Async::HTTP::ServerContext
	
	let(:rackup_path) {File.expand_path('../config.ru', __dir__)}
	let(:rackup_directory) {File.dirname(rackup_path)}
	
	let(:rack_app) {Rack::Builder.parse_file(rackup_path)}
	let(:app) {Protocol::Rack::Adapter.new(rack_app)}
end
