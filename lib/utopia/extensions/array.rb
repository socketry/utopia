#	This file is part of the "Utopia Framework" project, and is released under the MIT license.
#	Copyright 2010 Samuel Williams. All rights reserved.
#	See <utopia.rb> for licensing details.

class Array
	def find_index(&block)
		each_with_index do |item, index|
			if yield(item)
				return index
			end
		end
		
		return nil
	end
	
	def split_at(&block)
		index = find_index(&block)
		
		if index
			return [self[0...index], self[index], self[index+1..-1]]
		end
		
		return [[], nil, []]
	end
end
