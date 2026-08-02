# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2019-2025, by Samuel Williams.

require "msgpack"

require "time"
require "date"

module Utopia
	module Session
		# Encodes and decodes session values using MessagePack.
		class Serialization
			# Initialize a MessagePack factory with session-specific scalar types.
			def initialize
				@factory = MessagePack::Factory.new
				
				@factory.register_type(0x00, Symbol, packer: :to_msgpack_ext, unpacker: :from_msgpack_ext)
				
				@factory.register_type(0x01, Time, packer: :iso8601, unpacker: :parse)
				@factory.register_type(0x02, Date, packer: :iso8601, unpacker: :parse)
				@factory.register_type(0x03, DateTime, packer: :iso8601, unpacker: :parse)
			end
			
			attr :factory
			
			# Decode a MessagePack session value.
			# @parameter data [String] The serialized data.
			# @returns [Object] The decoded value.
			def load(data)
				@factory.unpack(data)
			end
			
			# Encode a session value using MessagePack.
			# @parameter object [Object] The value to encode.
			# @returns [String] The encoded value.
			def dump(object)
				@factory.pack(object)
			end
		end
	end
end
