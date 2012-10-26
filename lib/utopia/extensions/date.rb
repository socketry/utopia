# Copyright, 2012, by Samuel G. D. Williams. <http://www.codeotaku.com>
# 
# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:
# 
# The above copyright notice and this permission notice shall be included in
# all copies or substantial portions of the Software.
# 
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
# THE SOFTWARE.

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