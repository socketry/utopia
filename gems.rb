# frozen_string_literal: true

source 'https://rubygems.org'

gemspec

group :maintenance, optional: true do
	gem "bake-gem", "~> 0.3"
	gem "bake-modernize"
	
	gem "utopia-project"
end

group :development do
	gem 'json'
	gem 'rackula'
end

group :test do
	gem 'benchmark-ips'
	gem 'ruby-prof', platforms: :mri
	
	gem 'guard-falcon'
	
	gem 'rack-test'
end

gem "thread-local", "~> 1.0"
