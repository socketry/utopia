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

require_relative 'version'

require 'fileutils'
require 'find'

require 'yaml/store'

require 'samovar'
require 'securerandom'

module Utopia
	module Command
		module Setup
			# This path must point to utopia/setup in the gem source.
			BASE = File.expand_path("../../setup", __dir__)
			
			module Site
				CONFIGURATION_FILES = ['.bowerrc', 'config.ru', 'config/environment.rb', 'Gemfile', 'Rakefile', 'tasks/utopia.rake', 'tasks/bower.rake', 'tasks/test.rake']
				
				DIRECTORIES = ["config", "lib", "pages", "public", "tasks"]
				
				# Removed during upgrade process
				OLD_DIRECTORIES = ["access_log", "cache", "tmp"]
				
				ROOT = File.join(BASE, 'site')
			end
			
			module Server
				ROOT = File.join(BASE, 'server')
				
				def self.environment(root)
					# Setup config/environment.yaml according to specified options:
					environment_path = File.join(root, 'config/environment.yaml')
					FileUtils.mkpath File.dirname(environment_path)
					
					store = YAML::Store.new(environment_path)
					
					store.transaction do
						yield store
					end
				end
				
				# Set some useful defaults for the environment:
				def self.update_default_environment(root)
					# Set up some useful defaults for server environment:
					environment(root) do |store|
						store['RACK_ENV'] ||= 'production'
						store['UTOPIA_SESSION_SECRET'] ||= SecureRandom.hex(40)
					end
				end
			end
		end
		
		class Server < Samovar::Command
			class Create < Samovar::Command
				self.description = "Create a remote Utopia website suitable for deployment using git."
				
				def invoke(parent)
					destination_root = parent.root
					
					FileUtils.mkdir_p File.join(destination_root, "public")
					
					Dir.chdir(destination_root) do
						# Shared allows multiple users to access the site with the same group:
						system("git", "init", "--shared")
						system("git", "config", "receive.denyCurrentBranch", "ignore")
						system("git", "config", "core.worktree", destination_root)
					end
					
					# Copy git hooks:
					system("cp", "-r", File.join(Setup::Server::ROOT, 'git', 'hooks'), File.join(destination_root, '.git'))
					system("chmod", "-Rf", "g+w", File.join(destination_root, '.git/hooks'))
					
					Setup::Server.update_default_environment(destination_root)
					
					# Print out helpful git remote add message:
					hostname = `hostname`.chomp
					puts "Now add the git remote to your local repository:\n\tgit remote add production ssh://#{hostname}#{destination_root}"
					puts "Then push to it:\n\tgit push --set-upstream production master"
				end
			end
			
			class Update < Samovar::Command
				self.description = "Update the git hooks in an existing server repository."
				
				def invoke(parent)
					destination_root = parent.root
					
					Dir.chdir(destination_root) do
						system("git", "config", "receive.denyCurrentBranch", "ignore")
						system("git", "config", "core.sharedRepository", "group")
						system("git", "config", "core.worktree", destination_root)
					end
					
					# Copy git hooks:
					system("cp", "-r", File.join(Setup::Server::ROOT, 'git', 'hooks'), File.join(destination_root, '.git'))
					# finally set everything in the .git directory to be group writable
					system("chmod", "-Rf", "g+w", File.join(destination_root, '.git'))
					Setup::Server.update_default_environment(destination_root)
				end
			end
			
			class Environment < Samovar::Command
				self.description = "Update environment variables in config/environment.yaml"
				
				many :variables, "A list of environment KEY=VALUE pairs to set."
				
				def invoke(parent)
					return if variables.empty?
					
					destination_root = parent.root
					
					Setup::Server.environment(destination_root) do |store|
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
					end
				end
			end
			
			self.description = "Manage server deployments."
			
			nested '<command>',
				'create' => Create,
				'update' => Update,
				'environment' => Environment
			
			def invoke(parent)
				@command.invoke(parent)
			end
		end

		class Site < Samovar::Command
			class Create < Samovar::Command
				self.description = "Create a new local Utopia website using the default template."
				# self.example = "utopia --in www.example.com site create"
				
				def invoke(parent)
					destination_root = parent.root
					
					$stderr.puts "Setting up initial site in #{destination_root} for Utopia v#{Utopia::VERSION}..."
					
					Setup::Site::DIRECTORIES.each do |directory|
						FileUtils.mkdir_p(File.join(destination_root, directory))
					end
					
					Find.find(Setup::Site::ROOT) do |source_path|
						# What is this doing?
						destination_path = File.join(destination_root, source_path[Setup::Site::ROOT.size..-1])
						
						if File.directory?(source_path)
							FileUtils.mkdir_p(destination_path)
						else
							unless File.exist? destination_path
								FileUtils.copy_entry(source_path, destination_path)
							end
						end
					end
					
					Setup::Site::CONFIGURATION_FILES.each do |configuration_file|
						destination_path = File.join(destination_root, configuration_file)
						
						buffer = File.read(destination_path).gsub('$UTOPIA_VERSION', Utopia::VERSION)
						
						File.open(destination_path, "w") { |file| file.write(buffer) }
					end
					
					Dir.chdir(destination_root) do
						puts "Setting up site in #{destination_root}..."
						
						if `which bundle`.strip != ''
							puts "Generating initial package list with bundle..."
							system("bundle", "install", "--binstubs")
						end
						
						if `which git`.strip == ""
							$stderr.puts "Now is a good time to learn about git: http://git-scm.com/"
						elsif !File.exist?('.git')
							puts "Setting up git repository..."
							system("git", "init")
							system("git", "add", ".")
							system("git", "commit", "-q", "-m", "Initial Utopia v#{Utopia::VERSION} site.")
						end
					end
					
					name = `git config user.name || whoami`.chomp
					
					puts
					puts "  #{name},".ljust(78)
					puts "Thank you for using Utopia!".center(78)
					puts "We sincerely hope that Utopia helps to".center(78)
					puts "make your life easier and more enjoyable.".center(78)
					puts ""
					puts "To start the development server, run:".center(78)
					puts "rake server".center(78)
					puts ""
					puts "For extreme productivity, please consult the online documentation".center(78)
					puts "https://github.com/ioquatix/utopia".center(78)
					puts " ~ Samuel.  ".rjust(78)
				end
			end
			
			class Update < Samovar::Command
				self.description = "Upgrade an existing site to use the latest configuration files from the template."
				
				def move_static!
					if File.lstat("public/_static").symlink?
						FileUtils.rm_f "public/_static"
					end
					
					if File.directory?("pages/_static") and !File.exist?("public/_static")
						system("git", "mv", "pages/_static", "public/")
					end
				end
				
				def invoke(parent)
					destination_root = parent.root
					branch_name = "utopia-upgrade-#{Utopia::VERSION}"
					
					$stderr.puts "Upgrading #{destination_root}..."
					
					Dir.chdir(destination_root) do
						system('git', 'checkout', '-b', branch_name)
					end
					
					Setup::Site::DIRECTORIES.each do |directory|
						FileUtils.mkdir_p(File.join(destination_root, directory))
					end
					
					Setup::Site::OLD_DIRECTORIES.each do |directory|
						path = File.join(destination_root, directory)
						$stderr.puts "\tRemoving #{path}..."
						FileUtils.rm_rf(path)
					end
					
					Setup::Site::CONFIGURATION_FILES.each do |configuration_file|
						source_path = File.join(Setup::Site::ROOT, configuration_file)
						destination_path = File.join(destination_root, configuration_file)
						
						$stderr.puts "Updating #{destination_path}..."
						
						FileUtils.copy_entry(source_path, destination_path)
						buffer = File.read(destination_path).gsub('$UTOPIA_VERSION', Utopia::VERSION)
						File.open(destination_path, "w") { |file| file.write(buffer) }
					end
					
					begin
						Dir.chdir(destination_root) do
							# Stage any files that have been changed or removed:
							system("git", "add", "-u")
							
							# Stage any new files that we have explicitly added:
							system("git", "add", *Setup::Site::CONFIGURATION_FILES)
							
							move_static!
							
							# Commit all changes:
							system("git", "commit", "-m", "Upgrade to utopia #{Utopia::VERSION}.")
							
							# Checkout master..
							system("git", "checkout", "master")
							
							# and merge:
							system("git", "merge", "--squash", "--no-commit", branch_name)
						end
					rescue RuntimeError
						$stderr.puts "** Detected error with upgrade, reverting changes. Some new files may still exist in tree. **"
						
						system("git", "checkout", "master")
					ensure
						system("git", "branch", "-D", branch_name)
					end
				end
			end
			
			nested '<command>',
				'create' => Create,
				'update' => Update
			
			self.description = "Manage local utopia sites."
			
			def invoke(parent)
				@command.invoke(parent)
			end
		end
		
		class Top < Samovar::Command
			self.description = "A website development and deployment framework."
			
			options do
				option '-i/--in/--root <path>', "Work in the given root directory."
				option '-h/--help', "Print out help information."
				option '-v/--version', "Print out the application version."
			end
			
			nested '<command>',
				'site' => Site,
				'server' => Server
			
			def root
				File.expand_path(@options.fetch(:root, ''), Dir.getwd)
			end
			
			def invoke(program_name: File.basename($0))
				if @options[:version]
					puts "utopia v#{VERSION}"
				elsif @options[:help] or @command.nil?
					print_usage(program_name)
				else
					track_time do
						@command.invoke(self)
					end
				end
			end
		end
	end
end
