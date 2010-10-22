#	This file is part of the "Utopia Framework" project, and is licensed under the GNU AGPLv3.
#	Copyright 2010 Samuel Williams. All rights reserved.
#	See <utopia.rb> for licensing details.
require 'utopia/middleware'

module Utopia
	module Middleware

		# This class filters a incoming request and only executes a given block if it matches the given filter path.
		class Filter
			def initialize(app, filter, &block)
				@app = app
				@filter = filter
				branch = Rack::Builder.new(&block)
				branch.run(@app)
				@process = branch.to_app
			end

			def applicable(request)
				return request.path.index(@filter) != nil
			end

			def call(env)
				request = Rack::Request.new(env)

				if applicable(request)
					@process.call(env)
				else
					@app.call(env)
				end
			end
		end

	end
end
