# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2017-2023, by Samuel Williams.
# Copyright, 2020, by Michael Adams.

require 'fileutils'
require 'find'

require 'samovar'

module Utopia
	module Command
		# This path must point to utopia/setup in the gem source.
		SETUP_ROOT = File.expand_path("../../../setup", __dir__)
		
		# Local site setup commands.
		class Site < Samovar::Command
			# Configuration files which should be installed/updated:
			CONFIGURATION_FILES = ['.gitignore', 'config.ru', 'config/environment.rb', 'falcon.rb', 'gems.rb', 'Guardfile', 'bake.rb', 'test/website.rb', 'fixtures/website.rb']
			
			# Directories that should exist:
			DIRECTORIES = ["config", "lib", "pages", "public", "tasks", "spec"]
			
			# Directories that should be removed during upgrade process:
			OLD_PATHS = ["access_log", "cache", "tmp", "Rakefile", "tasks", ".bowerrc"]
			
			# The root directory of the template site:
			ROOT = File.join(SETUP_ROOT, 'site')
			
			# Create a local site.
			class Create < Samovar::Command
				self.description = "Create a new local Utopia website using the default template."
				
				def call
					destination_root = parent.root
					
					$stderr.puts "Setting up initial site in #{destination_root} for Utopia v#{Utopia::VERSION}..."
					
					DIRECTORIES.each do |directory|
						FileUtils.mkdir_p(File.join(destination_root, directory))
					end
					
					Find.find(ROOT) do |source_path|
						# What is this doing?
						destination_path = File.join(destination_root, source_path[ROOT.size..-1])
						
						if File.directory?(source_path)
							FileUtils.mkdir_p(destination_path)
						else
							unless File.exist? destination_path
								FileUtils.copy_entry(source_path, destination_path)
							end
						end
					end
					
					CONFIGURATION_FILES.each do |configuration_file|
						destination_path = File.join(destination_root, configuration_file)
						
						if File.exist?(destination_path)
							buffer = File.read(destination_path).gsub('$UTOPIA_VERSION', Utopia::VERSION)
							File.open(destination_path, "w") { |file| file.write(buffer) }
						else
							warn "Could not open #{destination_path}, maybe it should be removed from CONFIGURATION_FILES?"
						end
					end
					
					Dir.chdir(destination_root) do
						puts "Setting up site in #{destination_root}..."
						
						if `which bundle`.strip != ''
							puts "Generating initial package list with bundle..."
							system("bundle", "install") or fail "could not install bundled gems"
						end
						
						if `which git`.strip == ""
							$stderr.puts "Now is a good time to learn about git: http://git-scm.com/"
						elsif !File.exist?('.git')
							puts "Setting up git repository..."
							system("git", "init") or fail "could not create git repository"
							system("git", "add", ".") or fail "could not add all files"
							system("git", "commit", "-q", "-m", "Initial Utopia v#{Utopia::VERSION} site.") or fail "could not commit files"
						end
					end
					
					Environment.defaults(destination_root)
					
					name = `git config user.name || whoami`.chomp
					
					puts
					puts "  #{name},".ljust(78)
					puts "Thank you for using Utopia!".center(78)
					puts "We sincerely hope that Utopia helps to".center(78)
					puts "make your life easier and more enjoyable.".center(78)
					puts ""
					puts "To start the development server, run:".center(78)
					puts "bake utopia:development".center(78)
					puts ""
					puts "For extreme productivity, please consult the online documentation".center(78)
					puts "https://github.com/socketry/utopia".center(78)
					puts " ~ Samuel.  ".rjust(78)
				end
			end
			
			# Update a local site.
			class Update < Samovar::Command
				self.description = "Upgrade an existing site to use the latest configuration files from the template."
				
				# Move legacy `pages/_static` to `public/_static`.
				def move_static!
					# If public/_static doens't exist, we are done.
					return unless File.exist? 'pages/_static'
					
					if File.exist? 'public/_static'
						if File.lstat("public/_static").symlink?
							FileUtils.rm_f "public/_static"
						else
							warn "Can't move pages/_static to public/_static, destination already exists."
							return
						end
					end
					
					# One more sanity check:
					if File.directory? 'pages/_static'
						system("git", "mv", "pages/_static", "public/")
					end
				end
				
				# Move `Gemfile` to `gems.rb`.
				def update_gemfile!
					# If `Gemfile` doens't exist, we are done:
					return unless File.exist?('Gemfile')
					
					system("git", "mv", "Gemfile", "gems.rb")
					system("git", "mv", "Gemfile.lock", "gems.locked")
				end
				
				def call
					destination_root = parent.root
					branch_name = "utopia-upgrade-#{Utopia::VERSION}"
					
					$stderr.puts "Upgrading #{destination_root}..."
					
					Dir.chdir(destination_root) do
						system('git', 'checkout', '-b', branch_name) or fail "could not change branch"
					end
					
					DIRECTORIES.each do |directory|
						FileUtils.mkdir_p(File.join(destination_root, directory))
					end
					
					OLD_PATHS.each do |path|
						path = File.join(destination_root, path)
						$stderr.puts "\tRemoving #{path}..."
						FileUtils.rm_rf(path)
					end
					
					CONFIGURATION_FILES.each do |configuration_file|
						source_path = File.join(Site::ROOT, configuration_file)
						destination_path = File.join(destination_root, configuration_file)
						
						$stderr.puts "Updating #{destination_path}..."
						
						FileUtils.copy_entry(source_path, destination_path)
						buffer = File.read(destination_path).gsub('$UTOPIA_VERSION', Utopia::VERSION)
						File.open(destination_path, "w") { |file| file.write(buffer) }
					end
					
					Environment.defaults(destination_root)
					
					begin
						Dir.chdir(destination_root) do
							# Stage any files that have been changed or removed:
							system("git", "add", "-u") or fail "could not add files"
							
							# Stage any new files that we have explicitly added:
							system("git", "add", *Site::CONFIGURATION_FILES) or fail "could not add files"
							
							move_static!
							update_gemfile!
							
							# Commit all changes:
							system("git", "commit", "-m", "Upgrade to utopia #{Utopia::VERSION}.") or fail "could not commit changes"
							
							# Checkout master..
							system("git", "checkout", "master") or fail "could not checkout master"
							
							# and merge:
							system("git", "merge", "--squash", "--no-commit", branch_name) or fail "could not merge changes"
						end
					rescue RuntimeError
						$stderr.puts "** Detected error with upgrade, reverting changes. Some new files may still exist in tree. **"
						
						system("git", "checkout", "master")
					ensure
						system("git", "branch", "-D", branch_name)
					end
				end
			end
			
			nested :command, {
				'create' => Create,
				'update' => Update
			}
			
			self.description = "Manage local utopia sites."
			
			def root
				@parent.root
			end
			
			def call
				@command.call
			end
		end
	end
end
