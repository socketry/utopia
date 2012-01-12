#	This file is part of the "Utopia Framework" project, and is released under the MIT license.
#	Copyright 2010 Samuel Williams. All rights reserved.
#	See <utopia.rb> for licensing details.

require 'utopia/tags'

Utopia::Tags.create("node") do |transaction, state|
	path = Utopia::Path.create(state[:path])
	
	node = transaction.lookup_node(path)
	
	transaction.render_node(node)
end
