#	This file is part of the "Utopia Framework" project, and is licensed under the GNU AGPLv3.
#	Copyright 2010 Samuel Williams. All rights reserved.
#	See <utopia.rb> for licensing details.

# These amendments allow for Date <=> DateTime <=> Time, and so on.
# Use only if required. This implementation works for Ruby 1.9.2.

require 'date'

class Date
	alias_method :old_compare, :<=>
	
	def <=>(other)
		if other.class == Date
			old_compare(other)
		else
			if Time === other
				other = other.to_datetime
			end
			
		 	if DateTime === other
				result = old_compare(other.to_date)
				if result == 0 && other.day_fraction > 0
					-1
				else
					result
				end
			end
		end
	end
end

class Time
	alias_method :old_compare, :<=>
	
	def <=>(other)
		if other.class == Date
			(other <=> self) * -1
		elsif Time === other
			old_compare(other)
		else
			if DateTime === other
				other = other.to_time
			end
			
			old_compare(other)
		end
	end
end

class DateTime
	alias_method :old_compare, :<=>
	
	def <=>(other)
		if other.class == Date
			(other <=> self) * -1
		elsif DateTime === other
			old_compare(other)
		else
			if Time === other
				other = other.to_datetime
			end
			
			old_compare(other)
		end
	end
end