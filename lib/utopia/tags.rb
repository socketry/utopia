#	This file is part of the "Utopia Framework" project, and is released under the MIT license.
#	Copyright 2010 Samuel Williams. All rights reserved.
#	See <utopia.rb> for licensing details.

module Utopia
	module Tags
		@@all = {}
		
		def self.register(name, tag)
			@@all[name] = tag
		end
		
		def self.create(name, &block)
			@@all[name] = block
		end
		
		def self.all
			@@all
		end
	end
end
