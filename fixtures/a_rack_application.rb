# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2016-2023, by Samuel Williams.

require 'rack/test'
require 'rack/builder'

ARackApplication = Sus::Shared("a rack app") do |rackup_path|
	include Rack::Test::Methods
	
	let(:rackup_directory) {File.dirname(rackup_path)}
	let(:app) {Rack::Builder.parse_file(rackup_path)}
end
