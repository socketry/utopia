#	This file is part of the "Utopia Framework" project, and is licensed under the GNU AGPLv3.
#	Copyright 2010 Samuel Williams. All rights reserved.
#	See <utopia.rb> for licensing details.

require 'utopia/tags'

class Utopia::Tags::Override
	def self.tag_begin(transaction, state)
		state.overrides[state[:name]] = state[:with]
	end
	
	def self.call(transaction, state)
		transaction.parse_xml(state.content)
	end
end

Utopia::Tags.register("override", Utopia::Tags::Override)
