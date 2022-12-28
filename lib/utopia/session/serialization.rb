# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2019-2022, by Samuel Williams.

require 'msgpack'

require 'time'
require 'date'

module Utopia
	class Session
		class Serialization
			def initialize
				@factory = MessagePack::Factory.new
				
				@factory.register_type(0x00, Symbol, packer: :to_msgpack_ext, unpacker: :from_msgpack_ext)
				
				@factory.register_type(0x01, Time, packer: :iso8601, unpacker: :parse)
				@factory.register_type(0x02, Date, packer: :iso8601, unpacker: :parse)
				@factory.register_type(0x03, DateTime, packer: :iso8601, unpacker: :parse)
			end
			
			attr :factory
			
			def load(data)
				@factory.unpack(data)
			end
			
			def dump(object)
				@factory.pack(object)
			end
		end
	end
end
