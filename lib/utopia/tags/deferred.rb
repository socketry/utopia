#	This file is part of the "Utopia Framework" project, and is released under the MIT license.
#	Copyright 2010 Samuel Williams. All rights reserved.
#	See <utopia.rb> for licensing details.

require 'utopia/tags'

Utopia::Tags.create("deferred") do |transaction, state|
	id = state[:id].to_i
	
	procedure = transaction.parent.deferred[id]
	
	procedure.call(transaction, state)
end
