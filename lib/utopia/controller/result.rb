# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2016-2026, by Samuel Williams.

module Utopia
	module Controller
		# A semantic controller result awaiting response negotiation.
		Result = Data.define(:status, :headers, :value)
	end
end
