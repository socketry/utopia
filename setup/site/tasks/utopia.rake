
desc 'Run by git post-update hook when deployed to a web server'
task :deploy do
	# This task is typiclly run after the site is updated but before the server is restarted.
end

desc 'Restart the application server'
task :restart do
	# This task is run after the deployment task above.
	if passenger_config = `which passenger-config`.chomp!
		sh(passenger_config, 'restart-app', File.dirname(__dir__))
	end
end

desc 'Set up the environment for running your web application'
task :environment do
	require_relative '../config/environment'
end

desc 'Run a server for testing your web application'
task :server => :environment do
	port = ENV.fetch('SERVER_PORT', 9292).to_s
	exec('puma', '-v', '-p', port)
end

desc 'Start an interactive console for your web application'
task :console => :environment do
	require 'pry'
	require 'rack/test'
	
	include Rack::Test::Methods
	
	def app
		@app ||= Rack::Builder.parse_file(File.expand_path("../config.ru", __dir__)).first
	end
	
	Pry.start
end
