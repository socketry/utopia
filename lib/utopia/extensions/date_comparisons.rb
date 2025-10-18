# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2010-2025, by Samuel Williams.

require "date"

module Utopia
	module Extensions
		# Provides comparison operator extensions.
		module TimeDateComparison
			def <=>(other)
				if Date === other or DateTime === other
					self.to_datetime <=> other
				else
					super
				end
			end
		end
		
		::Time.prepend(TimeDateComparison)
		
		# Provides comparison operator extensions.
		module DateTimeComparison
			def <=>(other)
				if Time === other
					self.to_datetime <=> other.to_datetime
				else
					super
				end
			end
		end
		
		::Date.prepend(DateTimeComparison)
	end
end
