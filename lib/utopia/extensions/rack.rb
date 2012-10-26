#	This file is part of the "Utopia Framework" project, and is released under the MIT license.
#	Copyright 2010 Samuel Williams. All rights reserved.
#	See <utopia.rb> for licensing details.

require 'rack'

class Rack::Request
	def url_with_path(path = "")
		url = scheme + "://"
		url << host

		if scheme == "https" && port != 443 || scheme == "http" && port != 80
			url << ":#{port}"
		end

		url << path
	end
end

class Rack::Response
	def do_not_cache!
		self["Cache-Control"] = "no-cache, must-revalidate"
		self["Expires"] = Time.now.httpdate
	end
	
	def cache!(duration = 3600)
		unless (self["Cache-Control"] || "").match(/no-cache/)
			self["Cache-Control"] = "public, max-age=#{duration}"
			self["Expires"] = (Time.now + duration).httpdate
		end
	end
	
	def content_type!(value)
		self["Content-Type"] = value.to_s
	end
end
