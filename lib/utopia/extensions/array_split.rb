# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2009-2025, by Samuel Williams.

module Utopia
	# @namespace
	module Extensions
		# Adds splitting helpers to arrays.
		module ArraySplit
			# Split the array around the first element matching the arguments or block.
			# @parameter arguments [Array] The arguments accepted by {Array#index}.
			# @yields {|element| ...} Each element until the block matches.
			# @returns [Array(Array, Object, Array)] The elements before the match, the matching element, and the elements after it; the middle value is `nil` when no element matches.
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
