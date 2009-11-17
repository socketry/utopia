
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
