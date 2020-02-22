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
require 'thread/local'

require_relative 'logger'

module Utopia
	def self.root
		ENV.fetch('UTOPIA_ROOT') {Dir.pwd}
	end
	
	# Used for setting up a Utopia web application, typically via `config/environment.rb`
	class Setup
		extend Thread::Local
		
		def self.local
			self.new(Utopia.root, Utopia.variant)
		end
		
		def initialize(root, variant)
			@root = root
			@variant = variant
			@environment = nil
			
			@variant = ENV.fetch('UTOPIA_ENV', 'development').to_sym
		end
		
		attr :root
		
		# One of testing, staging, or production.
		attr :variant
		
		# The environment as loaded from `config/`
		def environment
			@environment ||= load_environment
		end
		
		# @param [Symbol] Typically one of `:test`, `:development`, or `:production`.
		attr :variant
		
		# For a given key, e.g. `:database`, fetch `DATABASE_ENV` in the process environment. If it exists, return it, otherwise default to the value of `self.variant`.
		def variant_for(key, default: @variant)
			ENV.fetch("#{key.upcase}_ENV", default).to_sym
		end
		
		def config_root
			File.expand_path("config", @root)
		end
		
		def site_root
			@root
		end
		
		def apply
			add_load_path('lib')
			
			require_relative '../utopia'
		end
		
		def production?
			@variant == :production
		end
		
		def development?
			@variant == :development
		end
		
		def test?
			@variant == :test
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
		
		def environment_path(variant, root = @root)
			File.expand_path("config/#{variant}.yaml", root)
		end
		
		# Load the named configuration file from the `config_root` directory.
		def load_environment(*args)
			path = environment_path(*args)
			
			if File.exist?(path)
				# Load the YAML environment file:
				environment = YAML.load_file(path)
			end
		end
	end
	
	def self.setup
		Setup.instance
	end
end
