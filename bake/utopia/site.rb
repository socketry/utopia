# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2017-2023, by Samuel Williams.
# Copyright, 2020, by Michael Adams.

def initialize(...)
	super
	
	require 'fileutils'
	require 'find'
	
	require_relative '../../lib/utopia/version'
end

# The path to the setup directory in the gem:
SETUP_ROOT = File.expand_path("../../setup", __dir__)

# Configuration files which should be installed/updated:
CONFIGURATION_FILES = ['.gitignore', 'config.ru', 'config/environment.rb', 'falcon.rb', 'gems.rb', 'Guardfile', 'bake.rb', 'test/website.rb', 'fixtures/website.rb']

# Directories that should exist:
DIRECTORIES = ["config", "lib", "pages", "public", "bake", "fixtures", "test"]

# Directories that should be removed during upgrade process:
OLD_PATHS = ["access_log", "cache", "tmp", "Rakefile", "tasks", ".bowerrc"]

# The root directory of the template site:
SITE_ROOT = File.join(SETUP_ROOT, 'site')

# Create a new local Utopia website using the default template.
def create(root: context.root)
	Console.logger.debug(self) {"Setting up site in #{root} for Utopia v#{Utopia::VERSION}..."}
	
	DIRECTORIES.each do |directory|
		FileUtils.mkdir_p(File.join(root, directory))
	end
	
	Find.find(SITE_ROOT) do |source_path|
		# Compute the destination path:
		destination_path = File.join(root, source_path[SITE_ROOT.size..-1])
		
		if File.directory?(source_path)
			# Create the directory:
			FileUtils.mkdir_p(destination_path)
		else
			# Copy the file, unless it already exists:
			unless File.exist? destination_path
				FileUtils.copy_entry(source_path, destination_path)
			end
		end
	end
	
	CONFIGURATION_FILES.each do |configuration_file|
		destination_path = File.join(root, configuration_file)
		
		if File.exist?(destination_path)
			buffer = File.read(destination_path).gsub('$UTOPIA_VERSION', Utopia::VERSION)
			File.open(destination_path, "w") { |file| file.write(buffer) }
		else
			Console.logger.warn(self) {"Could not open #{destination_path}, maybe it should be removed from CONFIGURATION_FILES?"}
		end
	end
	
	system("bundle", "install", chdir: root) or warn "could not install bundled gems"
	
	context.lookup('utopia:environment:setup').call(root: root)
	
	if !File.exist?('.git')
		Console.logger.info(self) {"Setting up git repository..."}
		
		system("git", "init", chdir: root) or warn "could not create git repository"
		system("git", "add", ".", chdir: root) or warn "could not add all files"
		system("git", "commit", "-q", "-m", "Initial Utopia v#{Utopia::VERSION} site.", chdir: root) or warn "could not commit files"
	end
	
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

# Upgrade an existing site to use the latest configuration files from the template.
def upgrade(root: context.root)
	message = "Upgrade to utopia v#{Utopia::VERSION}."
	
	Console.logger.info(self) {"Upgrading #{root}..."}
	
	commit_changes(root, message) do
		DIRECTORIES.each do |directory|
			FileUtils.mkdir_p(File.join(root, directory))
		end
		
		OLD_PATHS.each do |path|
			path = File.join(root, path)
			
			if File.exist?(path)
				Console.logger.info(self) {"Removing #{path}..."}
				FileUtils.rm_rf(path)
			end
		end
		
		CONFIGURATION_FILES.each do |configuration_file|
			source_path = File.join(SITE_ROOT, configuration_file)
			destination_path = File.join(root, configuration_file)
			
			Console.logger.info(self) {"Updating #{destination_path}..."}
			
			FileUtils.copy_entry(source_path, destination_path)
			buffer = File.read(destination_path).gsub('$UTOPIA_VERSION', Utopia::VERSION)
			File.open(destination_path, "w") { |file| file.write(buffer) }
		end
		
		context.lookup('utopia:environment:setup').call(root: root)
	
		# Stage any files that have been changed or removed:
		system("git", "add", "-u", chdir: root) or fail "could not add files"
		
		# Stage any new files that we have explicitly added:
		system("git", "add", *CONFIGURATION_FILES, chdir: root) or fail "could not add files"
		
		move_static!(root)
		update_gemfile!(root)
	end
end

private

def commit_changes(root, message)
	# Ensure the current branch is clean:
	system("git", "diff-index", "--quiet", "HEAD", chdir: root) or fail "current branch is not clean"
	
	begin
		yield
	rescue
		# Clear out the changes:
		system("git", "reset", "--hard", "HEAD", chdir: root) or fail "could not reset changes"
		raise
	end
	
	# Commit all changes:
	system("git", "commit", "-m", message, chdir: root) or fail "could not commit changes"
end

# Move legacy `pages/_static` to `public/_static`.
def move_static!(root)
	old_static_path = File.expand_path('pages/_static', root)
	
	# If public/_static doens't exist, we are done.
	return unless File.exist?(old_static_path)
	
	new_static_path = File.expand_path('public/_static', root)
	
	if File.exist?(new_static_path)
		if File.lstat(new_static_path).symlink?
			FileUtils.rm_f new_static_path
		else
			Console.logger.warn(self) {"Can't move pages/_static to public/_static, destination already exists."}
			return
		end
	end
	
	# One more sanity check:
	if File.directory?(old_static_path)
		system("git", "mv", "pages/_static", "public/")
	end
end

# Move `Gemfile` to `gems.rb`.
def update_gemfile!(root)
	gemfile_path = File.expand_path('Gemfile', root)
	
	# If `Gemfile` doens't exist, we are done:
	return unless File.exist?(gemfile_path)
	
	# If `gems.rb` already exists, we are done:
	gems_path = File.expand_path('gems.rb', root)
	return if File.exist?(gems_path)
	
	system("git", "mv", "Gemfile", "gems.rb", chdir: root)
	system("git", "mv", "Gemfile.lock", "gems.locked", chdir: root)
end
