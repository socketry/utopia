# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2020-2025, by Samuel Williams.

def deploy
	# This task is typiclly run after the site is updated but before the server is restarted.
end

# Restart the application server.
def restart
	puts "Restart the Falcon service using your process manager."
end

# Start the development server.
def default
	call "utopia:development"
end
