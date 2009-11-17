
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
							env["PATH_INFO"] = (path + file).to_s
							return @app.call(env)
						end
					end
				
					# Use the default path
					env["PATH_INFO"] = (path + @default).to_s
					return @app.call(env)
				else
					return @app.call(env)
				end
			end
		end

	end
end
