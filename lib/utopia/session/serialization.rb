# Copyright, 2014, by Samuel G. D. Williams. <http://www.codeotaku.com>
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
