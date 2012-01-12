#	This file is part of the "Utopia Framework" project, and is released under the MIT license.
#	Copyright 2010 Samuel Williams. All rights reserved.
#	See <utopia.rb> for licensing details.

require 'pathname'

Pathname.new(__FILE__).dirname.entries.each do |path|
	next unless /\.rb$/ === path.to_s

	name = File.basename(path.to_s, ".rb")
	
	if name != "all"
		require "utopia/middleware/#{name}"
	end
end
