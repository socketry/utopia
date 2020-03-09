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

require 'securerandom'
require 'yaml/store'
require 'console'

module Utopia
	module Command
		# Set environment variables within the server deployment.
		class Environment < Samovar::Command
			self.description = "Update environment variables in config/environment.yaml"
			
			options do
				option '-e/--environment-name <name>', "The environment file to modify.", default: 'environment'
				option '-d/--defaults', "Initialize any recommended defaults."
			end
			
			many :variables, "A list of environment KEY=VALUE pairs to set."
			
			def self.defaults(destination_root)
				# Set some useful defaults for the environment.
				self["--environment-name", "testing", "--defaults"].call(destination_root)
				self["--environment-name", "development", "--defaults"].call(destination_root)
			end
			
			def environment_name
				@options[:environment_name]
			end
			
			# Setup `config/environment.yaml` according to specified options.
			def update_environment(root, name = self.environment_name)
				environment_path = File.join(root, "config", "#{name}.yaml")
				FileUtils.mkpath File.dirname(environment_path)
				
				store = YAML::Store.new(environment_path)
				
				store.transaction do
					yield store, name, environment_path
				end
			end
			
			def call(root = parent.root)
				update_environment(root) do |store, name, path|
					if @options[:defaults]
						# Set some useful defaults for the environment.
						store['UTOPIA_SESSION_SECRET'] ||= SecureRandom.hex(40)
					end
					
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
					
					Console.logger.info(self) do |buffer|
						buffer.puts "Environment #{name} (#{path}):"
						store.roots.each do |key|
							value = store[key]
							
							buffer.puts "#{key}=#{value.inspect}"
						end
					end
				end
			end
		end
	end
end
