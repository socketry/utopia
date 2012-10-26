#	This file is part of the "Utopia Framework" project, and is released under the MIT license.
#	Copyright 2010 Samuel Williams. All rights reserved.
#	See <utopia.rb> for licensing details.

require 'utopia/middleware'
require 'utopia/path'

module Utopia
	module Middleware

		class DirectoryIndex
			def initialize(app, options = {})
				@app = app
				@root = options[:root] || Utopia::Middleware::default_root

				@files = ["index.html"]

				@default = "index"
			end

			def call(env)
				path = Path.create(env["PATH_INFO"])
				
				if path.directory?
					# Check to see if one of the files exists in the requested directory
					@files.each do |file|
						if File.exist?(File.join(@root, path.components, file))
							return [307, {"Location" => (path + file).to_s}, []]
						end
					end
				
					# Use the default path
					return [307, {"Location" => (path + @default).to_s}, []]
				else
					return @app.call(env)
				end
			end
		end

	end
end
