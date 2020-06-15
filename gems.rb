# frozen_string_literal: true

source 'https://rubygems.org'

# Specify your gem's dependencies in utopia.gemspec
gemspec

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
