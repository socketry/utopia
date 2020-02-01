# frozen_string_literal: true

class MockNode
	def initialize(namespaces = {}, &block)
		@namespaces = namespaces
		define_singleton_method(:call, block)
	end
	
	def lookup_tag(tag)
		namespace, name = Trenni::Tag.split(tag.name)
		
		if library = @namespaces[namespace]
			library.call(name, self)
		end
	end
end
