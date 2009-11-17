
require 'pathname'

Pathname.new(__FILE__).dirname.entries.grep(/\.rb$/).each do |path|
	name = File.basename(path.to_s, ".rb")
	
	if name != "all"
		require "utopia/middleware/#{name}"
	end
end
