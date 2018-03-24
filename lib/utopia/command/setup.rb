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
				CONFIGURATION_FILES = ['.bowerrc', '.gitignore', 'config.ru', 'config/environment.rb', 'Gemfile', 'Guardfile', 'Rakefile', 'tasks/bower.rake', 'tasks/deploy.rake', 'tasks/development.rake', 'tasks/environment.rake', 'tasks/log.rake']
				
				# Directories that should exist:
				DIRECTORIES = ["config", "lib", "pages", "public", "tasks"]
				
				# Directories that should be removed during upgrade process:
				OLD_PATHS = ["access_log", "cache", "tmp", 'tasks/test.rake', 'tasks/utopia.rake']
				
				# The root directory of the template site:
				ROOT = File.join(BASE, 'site')
			end
		end
	end
end
