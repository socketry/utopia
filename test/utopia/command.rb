# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2018-2025, by Samuel Williams.

require "fileutils"
require "yaml"

require "bundler"
require "sus/fixtures/temporary_directory_context"

describe "utopia command" do
	include Sus::Fixtures::TemporaryDirectoryContext
	
	let(:utopia_path) {File.expand_path("../..", __dir__)}
	
	def around
		Bundler.with_unbundled_env do
			super
		end
	end
	
	def group_rw(path)
		gaccess = File.stat(path).mode.to_s(8)[-2]
		return gaccess == "6" || gaccess == "7"
	end
	
	REQUIRED_GEMS = ["bake", "bake-test", "sus", "covered", "sus-fixtures-async-http", "falcon", "net-smtp", "benchmark-http"]
	
	def bundle_path
		File.join(utopia_path, "vendor/bundle")
	end
	
	def install_packages(dir)
		gems_path = File.join(dir, "gems.rb")
		File.open(gems_path, "w") do |file|
			file.puts "source 'https://rubygems.org'"
			file.puts "gem 'utopia', path: #{utopia_path.dump}"
			REQUIRED_GEMS.each do |gem|
				file.puts "gem '#{gem}'"
			end
		end
		
		system("bundle", "config", "set", "path", bundle_path, chdir: dir)
		system("bundle", "install", chdir: dir)
	end
	
	it "should generate sample site" do
		install_packages(root)
		
		system("bundle", "exec", "bake", "utopia:site:create", chdir: root, exception: true)
		
		expected_files = [".git", "gems.rb", "gems.locked", "readme.md", "bake.rb", "config", "lib", "pages", "public", "test"]
		site_files = Dir.entries(root)
		
		expected_files.each do |file|
			expect(site_files).to be(:include?, file)
		end
		
		expect(
			system("bundle", "exec", "bake", "test", chdir: root)
		).to be == true
	end
	
	it "should generate a sample server" do
		install_packages(root)
		
		system("bundle", "exec", "bake", "utopia:server:create", chdir: root, exception: true)
		expect(Dir.entries(root)).to be(:include?, ".git")
		
		system("git", "config", "--local", "core.sharedRepository", "false", chdir: root, exception: true)
		system("chmod", "-Rf", "g-x", ".git", chdir: root, exception: true)
		system("rm", "-f", ".git/hooks/post-receive", chdir: root, exception: true)
		
		environment = YAML.load_file(File.join(root, "config/environment.yaml"))
		expect(environment).to be(:include?, "VARIANT")
		expect(environment).to be(:include?, "UTOPIA_SESSION_SECRET")
	end
	
	it "should not trash the sample server during update" do
		install_packages(root)
		
		system("bundle", "exec", "bake", "utopia:server:create", chdir: root, exception: true)
		system("git", "config", "--local", "core.sharedRepository", "false", chdir: root, exception: true)
		system("chmod", "-Rf", "g-x", ".git", chdir: root, exception: true)
		system("rm", "-f", ".git/hooks/post-receive", chdir: root, exception: true)
		
		# Run the server update command:
		system("bundle", "exec", "bake", "utopia:server:update", chdir: root, exception: true)
		
		# Check a couple of files to make sure they have group read and write access after the update:
		Dir.glob(File.join(root, ".git/**/*")).each do |path|
			expect(group_rw(path)).to be == true
		end
	end
	
	it "can generate sample site, server and push to the server" do
		site_path = File.join(root, "site")
		FileUtils.mkdir_p(site_path)
		
		server_path = File.join(root, "server")
		FileUtils.mkdir_p(server_path)
		
		install_packages(site_path)
		install_packages(server_path)
		
		system("bundle", "exec", "bake", "utopia:site:create", chdir: site_path, exception: true)
		branch = IO.popen(["git", "branch", "--show-current"], chdir: site_path, &:read)
		expect(branch).to be == "main\n"
		
		system("bundle", "exec", "bake", "utopia:server:create", chdir: server_path, exception: true)
		branch = IO.popen(["git", "branch", "--show-current"], chdir: server_path, &:read)
		expect(branch).to be == "main\n"
		
		system("git", "push", "--set-upstream", server_path, "main", chdir: site_path, exception: true)
		
		expected_files = %W[.git gems.rb gems.locked readme.md bake.rb config lib pages public]
		server_files = Dir.entries(server_path)
		
		expected_files.each do |file|
			expect(server_files).to be(:include?, file)
		end
		
		expect(File.file? File.join(server_path, "config/application.rb")).to be == true
	end
end
