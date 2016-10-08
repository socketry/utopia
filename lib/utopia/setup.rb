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

module Utopia
	class Bootstrap
		def initialize(config_root)
			@config_root = config_root
		end
		
		def setup
			setup_encoding
			
			setup_environment
			
			setup_load_path
			
			require_relative '../utopia'
		end
		
		def environment_path
			File.expand_path('environment.yaml', @config_root)
		end
		
		def setup_encoding
			# If you don't specify these, it's possible to have issues when encodings mismatch on the server.
			Encoding.default_external = Encoding::UTF_8
			Encoding.default_internal = Encoding::UTF_8
		end
		
		def setup_environment
			if File.exist? environment_path
				require 'yaml'
				
				# Load the YAML environment file:
				environment = YAML.load_file(environment_path)
				
				# Update the process environment:
				ENV.update(environment)
			end
		end
		
		def setup_load_path
			# Allow loading library code from lib directory:
			$LOAD_PATH << File.expand_path('../lib', @config_root)
		end
	end
	
	def self.setup(config_root = nil, **options)
		# We extract the directory of the caller to get the path to $root/config
		if config_root.nil?
			config_root = File.dirname(caller[0])
		end
		
		Bootstrap.new(config_root).setup
	end
end
