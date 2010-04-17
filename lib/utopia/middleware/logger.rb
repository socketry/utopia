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
require 'utopia/time_store'

module Utopia
	module Middleware

		class Logger
			ACCESS_LOG = "access_log"
			HEADER = [:ip, :agent, :method, :url, :status, :location, :referer, :length]

			def write_log(env, response)
				request = Rack::Request.new(env)

				record = {
					:ip => request.ip,
					:host => request.host,
					:url => request.url,
					:referer => request.referer,
					:agent => env['HTTP_USER_AGENT'],
					:status => response[0],
					:method => request.request_method,
					:user => env['REMOTE_USER'],
					:version => env['HTTP_VERSION']
				}

				if response[1].key? "Location"
					record[:location] = response[1]["Location"]
				end
				
				if response[1].key? "Content-Length"
					record[:length] = response[1]["Content-Length"]
				end

				@log << record
			end

			def initialize(app, options = {})
				@app = app
				
				@log = options[:log] || TimeStore.new(options[:path] || ACCESS_LOG, options[:header] || HEADER)
			end

			def call(env)
				response = @app.call(env)

				Thread.new do
					write_log(env, response)
				end

				return response
			end
		end
	end
end
