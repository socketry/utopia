# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2018-2023, by Samuel Williams.

require 'fileutils'
require 'tmpdir'
require 'yaml'

require 'open3'
require 'bundler'

describe "utopia command" do
	let(:utopia_path) {File.expand_path("../..", __dir__)}
	let(:pkg_path) {File.expand_path("pkg", utopia_path)}
	let(:utopia) {File.expand_path("../../bin/utopia", __dir__)}
	
	def before
		# We need to build a package to test deployment:
		system("bundle", "exec", "bake", "gem:build", "--signing-key", "no") or abort("Could not build package for setup spec!")
		
		super
	end
	
	def around
		Bundler.with_unbundled_env do
			# In order to make this work in a vendored test environment, we need to seed the "local" environment with the "utopia" gem and all it's dependencies. Otherwise, the commands will fail because they can't find the dependencies (they are vendored in the source root but not in `dir`):
			system("bundle", "install", "--system")
			
			super
		end
	end
	
	def sh_status(*arguments)
		system(*arguments) ? 0 : false
	end
	
	def sh_stdout(*arguments)
		output, status = Open3.capture2(*arguments)
		return output
	end
	
	def git_config(name, value=nil)
		unless value.nil?
			return sh_status('git', 'config', name, value)
		else
			return sh_stdout('git', 'config', name).chomp
		end
	end
	
	def group_rw(path)
		gaccess = File.stat(path).mode.to_s(8)[-2]
		return gaccess == '6' || gaccess == '7'
	end
	
	def install_packages(dir)
		system("bundle", "config", "--local", "local.utopia", utopia_path, chdir: dir)
		system("bundle", "config", "--local", "cache_path", pkg_path, chdir: dir)
	end
	
	it "should generate sample site" do
		Dir.mktmpdir('test-site') do |dir|
			install_packages(dir)
			
			system(utopia, "--in", dir, "site", "create")
			
			expected_files = [".git", "gems.rb", "gems.locked", "readme.md", "bake.rb", "config.ru", "lib", "pages", "public", "spec"]
			site_files = Dir.entries(dir)
			
			expected_files.each do |file|
				expect(site_files).to be(:include?, file)
			end
			
			expect(
				system("bundle", "exec", "bake", "utopia:test", chdir: dir)
			).to be == true
		end
	end
	
	it "should generate a sample server" do
		Dir.mktmpdir('test-server') do |dir|
			install_packages(dir)
			
			result = sh_status(utopia, "--in", dir, "server", "create")
			expect(result).to be == 0
			
			expect(Dir.entries(dir)).to be(:include?, ".git")
			
			# make sure git is set up properly
			Dir.chdir(dir) do
				expect(git_config 'core.sharedRepository').to be == '1'
				expect(git_config 'receive.denyCurrentBranch').to be == 'ignore'
				expect(git_config 'core.worktree').to be == dir
			end
			
			environment = YAML.load_file(File.join(dir, 'config/environment.yaml'))
			expect(environment).to be(:include?, 'VARIANT')
			expect(environment).to be(:include?, 'UTOPIA_SESSION_SECRET')
		end
	end
	
	it "should not trash the sample server during update" do
		Dir.mktmpdir('test-server') do |dir|
			install_packages(dir)
			
			result = sh_status(utopia, "--in", dir, "server", "create")
			expect(result).to be == 0
			
			Dir.chdir(dir) do
				# make the repository look a bit like like it's an old one
				git_config 'core.sharedRepository', 'false'
				sh_status 'chmod', '-Rf', 'g-x', '.git'
				sh_status 'rm', '-f', '.git/hooks/post-receive'
			end
			
			result = sh_status(utopia, "--in", dir, "server", "update")
			expect(result).to be == 0
			
			# check a couple of files to make sure they have group read and write access
			# after the update
			Dir.glob(File.join(dir, '.git/**/*')).each do |path|
				expect(group_rw path).to be == true
			end
		end
	end
	
	it "can generate sample site, server and push to the server" do
		# This assumes your default branch is "main". We should probably be more flexible around this.
		# git config --global init.defaultBranch main
		Dir.mktmpdir('test') do |dir|
			site_path = File.join(dir, 'site')
			
			install_packages(site_path)
			
			server_path = File.join(dir, 'server')
			
			result = sh_status(utopia, "--in", site_path, "site", "create")
			expect(result).to be == 0
			
			result = sh_status(utopia, "--in", server_path, "server", "create")
			expect(result).to be == 0
			
			Dir.chdir(site_path) do
				result = sh_status("git", "push", "--set-upstream", server_path, "main")
				expect(result).to be == 0
			end
			
			expected_files = %W[.git gems.rb gems.locked readme.md bake.rb config.ru lib pages public]
			server_files = Dir.entries(server_path)
			
			expected_files.each do |file|
				expect(server_files).to be(:include?, file)
			end
			
			expect(File.executable? File.join(server_path, 'config.ru')).to be == true
			
			puts File.stat(File.join(dir, 'server', '.git')).mode
		end
	end
end
