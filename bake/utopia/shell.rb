# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2020, by Samuel Williams.

def shell
	call 'utopia:environment'
	
	require 'utopia/shell'
	
	binding = Utopia::Shell.new(self.context).binding
	
	IRB.setup(binding.source_location[0], argv: [])
	workspace = IRB::WorkSpace.new(binding)
	
	irb = IRB::Irb.new(workspace)
	irb.run(IRB.conf)
end
