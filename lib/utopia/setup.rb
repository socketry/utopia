# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2010-2026, by Samuel Williams.

require "yaml"
require "securerandom"

require "variant"

require "console"

module Utopia
	# Used for setting up a Utopia web application, typically via `config/environment.rb`
	class Setup
		# Initialize application setup for the given root.
		# @parameter root [String] The root directory.
		# @parameter options [Hash] Reserved setup options.
		def initialize(root, **options)
			@root = root
		end
		
		attr :root
		
		# Resolve the application's configuration directory.
		# @returns [String] The absolute configuration path.
		def config_root
			File.expand_path("config", @root)
		end
		
		# Return the application root.
		# @returns [String] The application root path.
		def site_root
			@root
		end
		
		# Check whether the application is running in production.
		# @returns [Boolean] Whether the active Utopia variant is `production`.
		def production?
			Variant.for(:utopia) == :production
		end
		
		# Check whether the application is running in staging.
		# @returns [Boolean] Whether the active Utopia variant is `staging`.
		def staging?
			Variant.for(:utopia) == :staging
		end
		
		# Check whether the application is running in development.
		# @returns [Boolean] Whether the active Utopia variant is `development`.
		def development?
			Variant.for(:utopia) == :development
		end
		
		# Check whether the application is running in testing.
		# @returns [Boolean] Whether the active Utopia variant is `testing`.
		def testing?
			Variant.for(:utopia) == :testing
		end
		
		# Fetch the configured secret for the given key.
		# @parameter key [String | Symbol] The lookup key.
		# @returns [String] The configured secret, or a newly generated transient secret when none is configured.
		def secret_for(key)
			secret = ENV["UTOPIA_#{key.upcase}_SECRET"]
			
			if secret.nil? || secret.empty?
				secret = SecureRandom.hex(32)
				
				Console.warn(self) do
					"Generating transient #{key} secret: #{secret.inspect}"
				end
			end
			
			return secret
		end
		
		# Apply.
		# @returns [self] This object.
		def apply!
			add_load_path("lib")
			
			apply_environment
			
			require_relative "../utopia"
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
				Console.debug(self){"Loading environment at path: #{path.inspect}"}
				
				# Load the YAML environment file:
				if environment = YAML.load_file(path)
					# We update ENV but only when it's not already set to something:
					ENV.update(environment) do |name, old_value, new_value|
						old_value || new_value
					end
				end
				
				return true
			else
				Console.debug(self){"Ignoring environment at path: #{path.inspect} (file not found)"}
				
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
