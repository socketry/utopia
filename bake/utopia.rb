# frozen_string_literal: true

# Set up the environment for the web application.
def environment(name: nil)
	require_relative '../lib/utopia/logger'
	
	if name
		ENV['UTOPIA_ENV'] = name
	end
	
	require File.expand_path('config/environment', context.root)
	
	Utopia.logger.info(self) {"Running in #{UTOPIA.environment_name}..."}
end

# Start the development server.
def development
	self.environment
	
	exec('guard', '-g', 'development')
end
