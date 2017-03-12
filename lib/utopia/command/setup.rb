# Copyright, 2016, by Samuel G. D. Williams. <http://www.codeotaku.com>
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

require 'fileutils'
require 'find'

require 'yaml/store'

require 'samovar'
require 'securerandom'

module Utopia
	module Command
		# The command for client/server setup.
		module Setup
			# This path must point to utopia/setup in the gem source.
			BASE = File.expand_path("../../../setup", __dir__)
			
			# Helpers for setting up a local site.
			module Site
				# Configuration files which should be installed/updated:
				CONFIGURATION_FILES = ['.bowerrc', 'config.ru', 'config/environment.rb', 'Gemfile', 'Rakefile', 'tasks/utopia.rake', 'tasks/bower.rake', 'tasks/test.rake']
				
				# Directories that should exist:
				DIRECTORIES = ["config", "lib", "pages", "public", "tasks"]
				
				# Directories that should be removed during upgrade process:
				OLD_DIRECTORIES = ["access_log", "cache", "tmp"]
				
				# The root directory of the template site:
				ROOT = File.join(BASE, 'site')
			end
			
			# Helpers for setting up the server deployment.
			module Server
				# The root directory of the template server deployment:
				ROOT = File.join(BASE, 'server')
				
				# Setup `config/environment.yaml` according to specified options.
				def self.environment(root)
					environment_path = File.join(root, 'config/environment.yaml')
					FileUtils.mkpath File.dirname(environment_path)
					
					store = YAML::Store.new(environment_path)
					
					store.transaction do
						yield store
					end
				end
				
				# Set some useful defaults for the environment.
				def self.update_default_environment(root)
					environment(root) do |store|
						store['RACK_ENV'] ||= 'production'
						store['UTOPIA_SESSION_SECRET'] ||= SecureRandom.hex(40)
					end
				end
			end
		end
	end
end
