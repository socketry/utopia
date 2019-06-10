
require "rspec/core/rake_task"

RSpec::Core::RakeTask.new(:test)

task :coverage do
	ENV['COVERAGE'] = 'PartialSummary'
end

desc 'Start the development server.'
task :server => :environment do
	exec('guard', '-g', 'development')
end

desc 'Start the development environment which includes web server and tests.'
task :development => :environment do
	exec('guard', '-g', 'development,test')
end

desc 'Start an interactive console for your web application'
task :console => :environment do
	require 'pry'
	require 'rack/test'
	
	include Rack::Test::Methods
	
	def app
		@app ||= Rack::Builder.parse_file(SITE_ROOT + 'config.ru').first
	end
	
	Pry.start
end
