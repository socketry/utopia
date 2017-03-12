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

require_relative 'setup'

module Utopia
	module Command
		# Local site setup commands.
		class Site < Samovar::Command
			# Create a local site.
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
							system("bundle", "install", "--binstubs") or fail "could not install bundled gems"
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
			
			# Update a local site.
			class Update < Samovar::Command
				self.description = "Upgrade an existing site to use the latest configuration files from the template."
				
				# Move legacy `pages/_static` to `public/_static`.
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
						system('git', 'checkout', '-b', branch_name) or fail "could not change branch"
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
							system("git", "add", "-u") or fail "could not add files"
							
							# Stage any new files that we have explicitly added:
							system("git", "add", *Setup::Site::CONFIGURATION_FILES) or fail "could not add files"
							
							move_static!
							
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
			
			nested '<command>',
				'create' => Create,
				'update' => Update
			
			self.description = "Manage local utopia sites."
			
			def invoke(parent)
				@command.invoke(parent)
			end
		end
	end
end
