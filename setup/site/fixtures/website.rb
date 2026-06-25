# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2016-2025, by Samuel Williams.

require "protocol/http/request"
require "sus/fixtures/async/http"
require "utopia/application"

AWebsite = Sus::Shared("a website") do
	let(:application_path) {File.expand_path("../config/application.rb", __dir__)}
	let(:application_directory) {File.dirname(application_path)}
	
	let(:app) {Utopia::Application.load(application_path)}
	
	def get(path)
		@last_response = app.call(Protocol::HTTP::Request["GET", path])
	end
	
	attr :last_response
end

AValidPage = Sus::Shared("a valid page") do |path|
	it "can access #{path}" do
		get path
		
		expect(last_response.status).to be == 200
	end
end

AServer = Sus::Shared("a server") do
	include Sus::Fixtures::Async::HTTP::ServerContext
	
	let(:application_path) {File.expand_path("../config/application.rb", __dir__)}
	let(:application_directory) {File.dirname(application_path)}
	
	let(:app) {Utopia::Application.load(application_path)}
end
