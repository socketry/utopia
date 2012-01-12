#	This file is part of the "Utopia Framework" project, and is licensed under the GNU AGPLv3.
#	Copyright 2010 Samuel Williams. All rights reserved.
#	See <utopia.rb> for licensing details.

require 'pathname'
require 'logger'

require 'utopia/http_status_codes'
require 'utopia/extensions/rack'

module Utopia
	LOG = Logger.new($stderr)
	LOG.level = Logger::DEBUG
	
	module Middleware
		def self.default_root(subdir = "pages")
			Pathname.new(Dir.pwd).join(subdir).cleanpath.to_s
		end
		
		def self.failure(status = 500, message = "Non-specific error")
			body = "#{HTTP_STATUS_DESCRIPTIONS[status] || status.to_s}: #{message}"
			
			return [status, {
				"Content-Type" => "text/plain",
				"Content-Length" => body.size.to_s,
				"X-Cascade" => "pass"
			}, [body]]
		end
	end
end

require 'utopia/path'
require 'utopia/tag'

