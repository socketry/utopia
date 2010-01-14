
require 'utopia/tags'

Utopia::Tags.create("node") do |transaction, state|
	path = Utopia::Path.create(state[:path])
	
	node = transaction.lookup_node(path)
	
	transaction.render_node(node)
end
