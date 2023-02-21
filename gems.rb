# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2012-2023, by Samuel Williams.

source 'https://rubygems.org'

gemspec

group :maintenance, optional: true do
	gem "bake-gem"
	gem "bake-modernize"
	
	gem "utopia-project"
end

group :development do
	gem 'json'
	gem 'rackula'
end

group :test do
	gem 'bake-test'
	gem 'bake-test-external'
	
	gem 'benchmark-ips'
	
	gem 'guard-falcon'
	
	gem 'rack-test'
end

gem "thread-local", "~> 1.0"
