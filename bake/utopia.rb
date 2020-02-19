# frozen_string_literal: true

# Set up the environment for the web application.
def environment(name: nil)
	require_relative '../lib/utopia/logger'
	
	if name
		ENV['UTOPIA_ENV'] = name
	end
	
	require File.expand_path('config/environment')
	
	Utopia.logger.info "Running with UTOPIA_ENV=#{UTOPIA_ENV}..."
end

# Start an interactive console for the web application.
def console
	self.environment
	
	require 'irb'
	require 'rack/test'
	
	include Rack::Test::Methods
	
	def app
		@app ||= Rack::Builder.parse_file('config.ru').first
	end
	
	ARGV.clear
	IRB.start
end

# Start the development server.
def development
	self.environment
	
	exec('guard', '-g', 'development')
end
