#	This file is part of the "Utopia Framework" project, and is licensed under the GNU AGPLv3.
#	Copyright 2010 Samuel Williams. All rights reserved.
#	See <utopia.rb> for licensing details.

module Utopia
	module Tags
		@@all = {}
		
		def self.register(name, tag)
			@@all[name] = tag
		end
		
		def self.create(name, &block)
			@@all[name] = Proc.new(&block)
		end
		
		def self.all
			@@all
		end
	end
end
