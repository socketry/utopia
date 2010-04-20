#	This file is part of the "Utopia Framework" project, and is licensed under the GNU AGPLv3.
#	Copyright 2010 Samuel Williams. All rights reserved.
#	See <utopia.rb> for licensing details.

require 'pathname'
require 'logger'

module Utopia
	LOG = Logger.new($stderr)
	LOG.level = Logger::DEBUG
	
	module Middleware
		def self.default_root(subdir = "pages")
			Pathname.new(Dir.pwd).join(subdir).realpath.to_s
		end
	end
end

require 'utopia/extensions'
require 'utopia/path'
require 'utopia/tag'

