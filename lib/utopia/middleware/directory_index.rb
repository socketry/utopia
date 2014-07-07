# Copyright, 2012, by Samuel G. D. Williams. <http://www.codeotaku.com>
# 
# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:
# 
# The above copyright notice and this permission notice shall be included in
# all copies or substantial portions of the Software.
# 
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
# THE SOFTWARE.

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
