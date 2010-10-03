#	This file is part of the "Utopia Framework" project, and is licensed under the GNU AGPLv3.
#	Copyright 2010 Samuel Williams. All rights reserved.
#	See <utopia.rb> for licensing details.

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
end
