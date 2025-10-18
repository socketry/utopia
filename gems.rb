# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2012-2025, by Samuel Williams.

source "https://rubygems.org"

gemspec

group :maintenance, optional: true do
	gem "bake-gem"
	gem "bake-modernize"
	gem "bake-releases"
	
	gem "agent-context"
	
	gem "utopia-project"
end

group :development do
	gem "json"
	gem "rackula"
end

group :test do
	gem "sus"
	gem "covered"
	gem "decode"
	
	gem "rubocop"
	gem "rubocop-md"
	gem "rubocop-socketry"
	
	gem "falcon"
	gem "async-websocket"
	gem "sus-fixtures-async-http"
	
	gem "bake-test"
	gem "bake-test-external"
	
	gem "benchmark-ips"
	
	gem "guard-falcon"
	
	gem "rack-test"
end
