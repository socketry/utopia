# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2018-2022, by Samuel Williams.

# Update environment variables in config/environment.yaml
def initialize(...)
	super
	
	require 'securerandom'
	require 'yaml/store'
	require 'console'
end

# Setup default environemnts "testing" and "development".
# @parameter root [String] The root directory of the project.
def setup(root: context.root)
	defaults(name: "testing", root: root)
	defaults(name: "development", root: root)
end

# Setup the defaults for a specific environment.
# @parameter name [String] The name of the environment to setup.
# @parameter root [String] The root directory of the project.
def defaults(name, root: context.root)
	update_environment(root, name) do |store|
		# Set some useful defaults for the environment.
		store['UTOPIA_SESSION_SECRET'] ||= SecureRandom.hex(40)
	end
end

# Update the specified environment.
# @parameter name [String] The name of the environment to update.
# @parameter variables [Hash(String, String)] A list of environment KEY=VALUE pairs to set.
def update(name, root: context.root, **variables)
	update_environment(root, name) do |store|
		variables&.each do |variable|
			key, value = variable.split('=', 2)
			
			if value
				puts "ENV[#{key.inspect}] will default to #{value.inspect} unless otherwise specified."
				store[key] = value
			else
				puts "ENV[#{key.inspect}] will be unset unless otherwise specified."
				store.delete(key)
			end
		end
		
		yield store if block_given?
		
		Console.logger.debug(self) do |buffer|
			buffer.puts "Environment #{name} (#{path}):"
			store.roots.each do |key|
				value = store[key]
				
				buffer.puts "#{key}=#{value.inspect}"
			end
		end
	end
end

def read(name, root: context.root)
	environment_path = self.environment_path(root, name)
	
	if File.exist?(environment_path)
		Console.logger.debug(self) {"Loading environment #{name} from #{environment_path}..."}
		YAML.load_file(environment_path)
	else
		Console.logger.debug(self) {"No environment #{name} found at #{environment_path}."}
		{}
	end
end

private

def environment_path(root, name)
	File.join(root, "config", "#{name}.yaml")
end

# Setup `config/environment.yaml` according to specified options.
def update_environment(root, name)
	environment_path = self.environment_path(root, name)
	FileUtils.mkpath File.dirname(environment_path)
	
	store = YAML::Store.new(environment_path)
	
	store.transaction do
		yield store, name, environment_path
	end
end
