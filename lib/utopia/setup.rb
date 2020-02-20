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

require_relative 'logger'

module Utopia
	# Used for setting up a Utopia web application, typically via `config/environment.rb`
	class Setup
		def initialize(config_root, external_encoding: Encoding::UTF_8)
			@config_root = config_root
			
			@external_encoding = external_encoding
			
			@environment = nil
		end
		
		attr :config_root
		attr :external_encoding
		attr :environment
		
		# For a given key, fetch `KEY_ENV` in the process environment. If it exists, return it, otherwise default to the value of `UTOPIA_ENV`.
		def environment_name(key = nil, default: 'development')
			if key
				ENV.fetch("#{key.upcase}_ENV") do
					ENV.fetch('UTOPIA_ENV', default)
				end
			else
				ENV.fetch("UTOPIA_ENV", default)
			end
		end
		
		def site_root
			File.dirname(@config_root)
		end
		
		def apply
			set_external_encoding
			
			apply_environment
			
			add_load_path('lib')
			
			require_relative '../utopia'
		end
		
		def production?
			self.environment_name == 'production'
		end
		
		def development?
			self.environment_name == 'development'
		end
		
		def test?
			self.environment_name == 'test'
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
		
		DEFAULT_ENVIRONMENT_NAME = :environment
		
		def apply_environment
			load_environment(
				self.environment_name(default: DEFAULT_ENVIRONMENT_NAME)
			)
		end
		
		# Add the given path to $LOAD_PATH. If it's relative, make it absolute relative to `site_path`.
		def add_load_path(path)
			# Allow loading library code from lib directory:
			$LOAD_PATH << File.expand_path(path, site_root)
		end
		
		private
		
		def environment_path(name, root = @config_root)
			File.expand_path("#{name}.yaml", root)
		end
		
		# If you don't specify these, it's possible to have issues when encodings mismatch on the server.
		def set_external_encoding(encoding = Encoding::UTF_8)
			# TODO: Deprecate and remove this setup - it should be the responsibility of the server to set this correctly.
			if Encoding.default_external != encoding
				warn "Updating Encoding.default_external from #{Encoding.default_external} to #{encoding}" if $VERBOSE
				Encoding.default_external = encoding
			end
		end
		
		# Load the named configuration file from the `config_root` directory.
		def load_environment(*args)
			path = environment_path(*args)
			
			if File.exist?(path)
				# Load the YAML environment file:
				@environment = YAML.load_file(path)
				
				# We update ENV but only when it's not already set to something:
				ENV.update(@environment) do |name, old_value, new_value|
					old_value || new_value
				end
			end
		end
	end
	
	# The main entry point for `config/environment.rb` for setting up the site.
	def self.setup(config_root = nil, **options)
		# We extract the directory of the caller to get the path to $root/config
		if config_root.nil?
			config_root = File.dirname(caller[0])
		end
		
		Setup.new(config_root, **options).tap(&:apply)
	end
end
