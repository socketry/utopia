#	This file is part of the "Utopia Framework" project, and is licensed under the GNU AGPLv3.
#	Copyright 2010 Samuel Williams. All rights reserved.
#	See <utopia.rb> for licensing details.

module Rack
	class Response
		def self.create(response, &block)
			self.new(response[2], response[0], response[1], &block)
		end
	end
end