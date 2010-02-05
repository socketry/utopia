
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
