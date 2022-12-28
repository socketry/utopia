# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2015-2022, by Samuel Williams.

module Utopia
	# A structured representation of locale based on RFC3066.
	Locale = Struct.new(:language, :country, :variant) do
		def to_s
			to_a.compact.join('-')
		end
		
		def self.dump(instance)
			if instance
				instance.to_s
			end
		end
		
		def self.load(instance)
			if instance.is_a? String
				self.new(*instance.split('-', 3))
			elsif instance.is_a? Array
				return self.new(*instance)
			elsif instance.is_a? self
				return instance.frozen? ? instance : instance.dup
			end
		end
	end
end
