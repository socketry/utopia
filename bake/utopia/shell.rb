# frozen_string_literal: true

# Start an interactive console for the web application.
def shell
	call 'utopia:environment'
	
	require 'utopia/shell'
	
	Utopia::Shell.new(self.context).binding.irb
end
