#	This file is part of the "Utopia Framework" project, and is licensed under the GNU AGPLv3.
#	Copyright 2010 Samuel Williams. All rights reserved.
#	See <utopia.rb> for licensing details.

class Date
	alias_method :old_cmp, :<=>
	
	def <=> (other)
		# Comparing a Date with something that has a time component truncates the time
		# component, thus we need to check if the other object has a more exact comparison
		# function.
		if other.respond_to?(:hour)
			return (other <=> self) * -1
		else
			old_cmp(other)
		end
	end	
end
