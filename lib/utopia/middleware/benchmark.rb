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
				# LOG.debug "benchmark: Request #{env["PATH_INFO"]} took #{time}s"
				buf = StringIO.new

				response[2].each do |text|
					buf.write(text.gsub(@tag, time))
				end

				buf.rewind

				[response[0], response[1], buf]
			end
		end

	end
end
