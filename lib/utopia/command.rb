# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2016-2022, by Samuel Williams.
# Copyright, 2017, by Huba Nagy.

require_relative 'version'

require_relative 'command/site'
require_relative 'command/server'
require_relative 'command/environment'

module Utopia
	module Command
		def self.call(*arguments)
			Top.call(*arguments)
		end
		
		# The top level utopia command.
		class Top < Samovar::Command
			self.description = "A website development and deployment framework."
			
			options do
				option '-i/--in/--root <path>', "Work in the given root directory."
				option '-h/--help', "Print out help information."
				option '-v/--version', "Print out the application version."
			end
			
			nested :command, {
				'site' => Site,
				'server' => Server,
				'environment' => Environment
			}
			
			# The root directory for the site.
			def root
				File.expand_path(@options.fetch(:root, ''), Dir.getwd)
			end
			
			def call
				if @options[:version]
					puts "#{self.name} v#{VERSION}"
				elsif @options[:help]
					print_usage(output: $stdout)
				else
					@command.call
				end
			end
		end
	end
end
