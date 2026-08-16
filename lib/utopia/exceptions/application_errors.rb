# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2026, by Samuel Williams.

module Utopia
	module Exceptions
		# Exceptions raised by application code which can be safely handled and reported.
		APPLICATION_ERRORS = [StandardError, ScriptError].freeze
	end
end
