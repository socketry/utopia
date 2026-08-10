# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2026, by Samuel Williams.

module Utopia
	module Redirection
		Rule = Data.define(:status, :max_age, :resolver) do
			def call(path)
				resolver.call(path)
			end
		end
		
		private_constant :Rule
	end
end
