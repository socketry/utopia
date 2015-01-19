
require 'simplecov'
SimpleCov.start do
	add_filter "/spec/"
end if ENV["COVERAGE"]

require 'rack/mock'
require 'rack/test'
