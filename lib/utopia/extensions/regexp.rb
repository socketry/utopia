#	This file is part of the "Utopia Framework" project, and is released under the MIT license.
#	Copyright 2010 Samuel Williams. All rights reserved.
#	See <utopia.rb> for licensing details.

class Regexp
	def self.starts_with(string)
		return /^#{Regexp.escape(string)}/
	end

	def self.ends_with(string)
		return /#{Regexp.escape(string)}$/
	end

	def self.contains(string)
		return Regexp.new(string)
	end
end
