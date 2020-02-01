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

module Utopia
	module Command
		# Set environment variables within the server deployment.
		class Environment < Samovar::Command
			self.description = "Update environment variables in config/environment.yaml"
			
			options do
				option '-e/--environment-name <name>', "The environment file to modify.", default: 'environment'
			end
			
			many :variables, "A list of environment KEY=VALUE pairs to set."
			
			# Setup `config/environment.yaml` according to specified options.
			def update_environment(root, name = @options[:environment_name])
				environment_path = File.join(root, "config", "#{name}.yaml")
				FileUtils.mkpath File.dirname(environment_path)
				
				store = YAML::Store.new(environment_path)
				
				store.transaction do
					yield store
				end
			end
			
			def invoke(parent)
				destination_root = parent.root
				
				update_environment(destination_root) do |store|
					variables.each do |variable|
						key, value = variable.split('=', 2)
						
						if value
							puts "ENV[#{key.inspect}] will default to #{value.inspect} unless otherwise specified."
							store[key] = value
						else
							puts "ENV[#{key.inspect}] will be unset unless otherwise specified."
							store.delete(key)
						end
					end
					
					store.roots.each do |key|
						value = store[key]
						
						puts "#{Rainbow(key).blue}: #{Rainbow(value.inspect).green}"
					end
				end
			end
		end
	end
end
