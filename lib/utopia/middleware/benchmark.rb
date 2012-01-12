#	This file is part of the "Utopia Framework" project, and is released under the MIT license.
#	Copyright 2010 Samuel Williams. All rights reserved.
#	See <utopia.rb> for licensing details.

require 'utopia/middleware'

module Utopia
	module Middleware

		class Benchmark
			def initialize(app, options = {})
				@app = app
				@tag = options[:tag] || "{{benchmark}}"
			end

			def call(env)
				start = Time.now
				response = @app.call(env)
				finish = Time.now

				time = "%0.4f" % (finish - start)
				env['rack.errors'].puts "Benchmark: Request #{env["PATH_INFO"]} took #{time}s"
				
				return response
			end
		end

	end
end
