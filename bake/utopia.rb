# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2017-2025, by Samuel Williams.

def environment(name: nil)
	if name
		ENV["UTOPIA_ENV"] = name
	end
	
	require File.expand_path("config/environment", context.root)
end

# Start the development server.
def development
	self.environment
	
	exec("guard", "-g", "development")
end
