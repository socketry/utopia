# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2010-2022, by Samuel Williams.

module Utopia
	module Extensions
		module ArraySplit
			def split_at(*arguments, &block)
				if middle = index(*arguments, &block)
					[self[0...middle], self[middle], self[middle+1..-1]]
				else
					[[], nil, []]
				end
			end
		end

		::Array.prepend(ArraySplit)
	end
end
