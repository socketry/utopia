# Copyright (c) 2010 Samuel Williams. Released under the GNU GPLv3.
#
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
# 
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
# 
# You should have received a copy of the GNU General Public License
# along with this program.  If not, see <http://www.gnu.org/licenses/>.

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
