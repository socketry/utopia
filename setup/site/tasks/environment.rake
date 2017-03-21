
desc 'Set up the environment for running your web application'
task :environment do
	require_relative '../config/environment'
	
	# We ensure this is part of the shell environment so if other commands are invoked they will work correctly.
	ENV['RACK_ENV'] = RACK_ENV.to_s if defined?(RACK_ENV)
	ENV['DATABASE_ENV'] = DATABASE_ENV.to_s if defined?(DATABASE_ENV)
end
