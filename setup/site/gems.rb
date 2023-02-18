# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2012-2023, by Samuel Williams.

source 'https://rubygems.org'

group :preload do
	gem 'utopia', '~> $UTOPIA_VERSION'
	# gem 'utopia-gallery'
	# gem 'utopia-analytics'
	
	gem 'variant'
end

gem 'bake'
gem 'bundler'
gem 'rack-test'
gem 'net-smtp'

group :development do
	gem 'guard-falcon', require: false
	
	gem 'sus'
	gem 'sus-fixtures-async-http'
	
	gem 'covered'
	
	gem 'benchmark-http'
end

group :production do
	gem 'falcon'
end
