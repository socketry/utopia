
module Rack
	class Response
		def self.create(response, &block)
			self.new(response[2], response[0], response[1], &block)
		end
	end
end