
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

