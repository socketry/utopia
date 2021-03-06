# frozen_string_literal: true

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

require 'yaml'
require 'securerandom'

require 'variant'

require_relative 'logger'

module Utopia
	# Used for setting up a Utopia web application, typically via `config/environment.rb`
	class Setup
		def initialize(root, **options)
			@root = root
		end
		
		attr :root
		
		def config_root
			File.expand_path("config", @root)
		end
		
		def site_root
			@root
		end
		
		def production?
			Variant.for(:utopia) == :production
		end
		
		def staging?
			Variant.for(:utopia) == :staging
		end
		
		def development?
			Variant.for(:utopia) == :development
		end
		
		def testing?
			Variant.for(:utopia) == :testing
		end
		
		def secret_for(key)
			secret = ENV["UTOPIA_#{key.upcase}_SECRET"]
			
			if secret.nil? || secret.empty?
				secret = SecureRandom.hex(32)
				
				Utopia.logger.warn(self) do
					"Generating transient #{key} secret: #{secret.inspect}"
				end
			end
			
			return secret
		end
		
		def apply!
			add_load_path('lib')
			
			apply_environment
			
			require_relative '../utopia'
		end
		
		private
		
		def apply_environment
			# First try to load `config/environment.yaml` if it exists:
			load_environment(:environment)
			
			# NOTE: loading the environment above MAY set `VARIANT`. So, it's important to look up the variant AFTER loading that environment.
			
			# Then, try to load the variant specific environment:
			variant = Variant.for(:utopia)
			load_environment(variant)
		end
		
		# Add the given path to $LOAD_PATH. If it's relative, make it absolute relative to `site_path`.
		def add_load_path(path)
			# Allow loading library code from lib directory:
			$LOAD_PATH << File.expand_path(path, site_root)
		end
		
		def environment_path(variant)
			File.expand_path("config/#{variant}.yaml", @root)
		end
		
		# Load the named configuration file from the `config_root` directory.
		def load_environment(variant)
			path = environment_path(variant)
			
			if File.exist?(path)
				Utopia.logger.debug(self) {"Loading environment at path: #{path.inspect}"}
				
				# Load the YAML environment file:
				if environment = YAML.load_file(path)
					# We update ENV but only when it's not already set to something:
					ENV.update(environment) do |name, old_value, new_value|
						old_value || new_value
					end
				end
				
				return true
			else
				Utopia.logger.debug(self) {"Ignoring environment at path: #{path.inspect} (file not found)"}
				
				return false
			end
		end
	end
	
	@setup = nil
	
	# You can call this method exactly once per process.
	def self.setup(root = nil, **options)
		if @setup
			raise RuntimeError, "Utopia already setup!"
		end
		
		# We extract the root from the caller of this method:
		if root.nil?
			config_root = File.dirname(caller[0])
			root = File.dirname(config_root)
		end
		
		@setup = Setup.new(root, **options)
		
		@setup.apply!
		
		return @setup
	end
end
