# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2017-2025, by Samuel Williams.

def initialize(...)
	super
	
	require "fileutils"
	require "socket"
end

# Create a remote Utopia website suitable for deployment using git.
def create(root: context.root)
	FileUtils.mkdir_p File.join(root, "public")
	
	update(root: root)
	
	# Print out helpful git remote add message:
	puts "Now add the git remote to your local repository:\n\tgit remote add production ssh://#{Socket.gethostname}#{root}"
	puts "Then push to it:\n\tgit push --set-upstream production main"
end

# The path to the setup directory in the gem:
SETUP_ROOT = File.expand_path("../../setup", __dir__)

# The root directory of the template server deployment:
SERVER_ROOT = File.join(SETUP_ROOT, "server")

# Update the git hooks in an existing server repository.
def update(root: context.root)
	# It's okay to call this on an existing repo, it will only update config as required to enable --shared.
	# --shared allows multiple users to access the site with the same group.
	system("git", "init", "--shared", chdir: root) or fail "could not initialize repository"
	
	system("git", "config", "receive.denyCurrentBranch", "ignore", chdir: root) or fail "could not set configuration"
	system("git", "config", "core.worktree", root, chdir: root) or fail "could not set configuration"
	
	# Doing this invokes a lot of behaviour that isn't always ideal...
	# system("bundle", "config", "set", "--local", "deployment", "true")
	system("bundle", "config", "set", "--local", "without", "development", chdir: root) or fail "could not set bundle configuration"
	
	# In theory, to convert from non-shared to shared:
	# chgrp -R <group-name> .                   # Change files and directories' group
	# chmod -R g+w .                            # Change permissions
	# chmod g-w .git/objects/pack/*             # Git pack files should be immutable
	# chmod g+s `find . -type d`                # New files get group id of directory
	
	# Set some useful defaults for the environment.
	recipe = context.lookup("utopia:environment:update")
	recipe.instance.update("environment", root: root) do |store|
		store["VARIANT"] ||= "production"
		store["UTOPIA_SESSION_SECRET"] ||= SecureRandom.hex(40)
	end
	
	# Copy git hooks:
	system("cp", "-r", File.join(SERVER_ROOT, "git", "hooks"), File.join(root, ".git")) or fail "could not copy git hooks"
	# finally set everything in the .git directory to be group writable
	# This failed for me and I had to do sudo chown http:http .git -R first.
	system("chmod", "-Rf", "g+w", File.join(root, ".git")) or fail "could not update permissions of .git directory"
end
