
if ENV['TRAVIS']
	require 'coveralls'
	Coveralls.wear!
end

if ENV['COVERAGE']
	require 'simplecov'
	
	SimpleCov.start do
		add_filter "/spec/"
	end if ENV["COVERAGE"]
end

require 'rack/mock'
require 'rack/test'
