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
		# Server setup commands.
		class Server < Samovar::Command
			# Create a server.
			class Create < Samovar::Command
				self.description = "Create a remote Utopia website suitable for deployment using git."
				
				def invoke(parent)
					destination_root = parent.root
					
					FileUtils.mkdir_p File.join(destination_root, "public")
					
					Update.new.invoke(parent)
					
					# Print out helpful git remote add message:
					hostname = `hostname`.chomp
					puts "Now add the git remote to your local repository:\n\tgit remote add production ssh://#{hostname}#{destination_root}"
					puts "Then push to it:\n\tgit push --set-upstream production master"
				end
			end
			
			# Update a server.
			class Update < Samovar::Command
				self.description = "Update the git hooks in an existing server repository."
				
				def invoke(parent)
					destination_root = parent.root
					
					Dir.chdir(destination_root) do
						# It's okay to call this on an existing repo, it will only update config as required to enable --shared.
						# --shared allows multiple users to access the site with the same group.
						system("git", "init", "--shared") or fail "could not initialize repository"
						
						system("git", "config", "receive.denyCurrentBranch", "ignore") or fail "could not set configuration"
						system("git", "config", "core.worktree", destination_root) or fail "could not set configuration"
						
						# In theory, to convert from non-shared to shared:
						# chgrp -R <group-name> .                   # Change files and directories' group
						# chmod -R g+w .                            # Change permissions
						# chmod g-w .git/objects/pack/*             # Git pack files should be immutable
						# chmod g+s `find . -type d`                # New files get group id of directory
					end
					
					Setup::Server.update_default_environment(destination_root)
					
					# Copy git hooks:
					system("cp", "-r", File.join(Setup::Server::ROOT, 'git', 'hooks'), File.join(destination_root, '.git')) or fail "could not copy git hooks"
					# finally set everything in the .git directory to be group writable
					system("chmod", "-Rf", "g+w", File.join(destination_root, '.git')) or fail "could not update permissions of .git directory"
				end
			end
			
			# Set environment variables within the server deployment.
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
	end
end
