# frozen_string_literal: true

# Start an interactive console for the web application.
def shell
	call 'utopia:environment'
	
	require 'utopia/shell'
	
	binding = Utopia::Shell.new(self.context).binding
	
	IRB.setup(binding.source_location[0], argv: [])
	workspace = IRB::WorkSpace.new(binding)
	
	irb = IRB::Irb.new(workspace)
	irb.run(IRB.conf)
end
