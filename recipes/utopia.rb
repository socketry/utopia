# frozen_string_literal: true

recipe :environment, description: 'Set up the environment for the web application' do |name: nil|
	require_relative '../lib/utopia/logger'
	
	if name
		ENV['UTOPIA_ENV'] = name
	end
	
	require File.expand_path('config/environment')
	
	# We ensure this is part of the shell environment so if other commands are invoked they will work correctly.
	ENV['RACK_ENV'] = RACK_ENV.to_s if defined?(RACK_ENV)
	ENV['DATABASE_ENV'] = DATABASE_ENV.to_s if defined?(DATABASE_ENV)
	ENV['UTOPIA_ENV'] = UTOPIA_ENV.to_s if defined?(UTOPIA_ENV)
	
	Utopia.logger.info "Running with UTOPIA_ENV=#{UTOPIA_ENV}..."
	
	# This generates a consistent session secret if one was not already provided:
	if ENV['UTOPIA_SESSION_SECRET'].nil?
		require 'securerandom'
		
		Utopia.logger.warn 'Generating transient session key for development...'
		ENV['UTOPIA_SESSION_SECRET'] = SecureRandom.hex(32)
	end
end

recipe :console, description: 'Start an interactive console for the web application.' do
	call 'utopia:environment'
	
	require 'irb'
	require 'rack/test'
	
	include Rack::Test::Methods
	
	def app
		@app ||= Rack::Builder.parse_file('config.ru').first
	end
	
	ARGV.clear
	IRB.start
end

recipe :development, description: 'Start the development server.' do
	call :environment
	
	exec('guard', '-g', 'development')
end
