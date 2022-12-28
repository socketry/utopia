# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2016-2022, by Samuel Williams.

require 'rack/test'

RSpec.shared_context "rack app" do |relative_rackup_path|
	include Rack::Test::Methods
	
	let(:rackup_path) {File.expand_path(relative_rackup_path, __dir__)}
	let(:rackup_directory) {File.dirname(rackup_path)}
	
	let(:app) {Rack::Builder.parse_file(rackup_path)}
end
