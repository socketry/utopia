#	This file is part of the "Utopia Framework" project, and is released under the MIT license.
#	Copyright 2010 Samuel Williams. All rights reserved.
#	See <utopia.rb> for licensing details.

class Hash
	def symbolize_keys
		inject({}) do |options, (key, value)|
			options[(key.to_sym rescue key) || key] = value
			options
		end
	end
end
