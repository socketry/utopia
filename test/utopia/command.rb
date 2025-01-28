# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2018-2025, by Samuel Williams.

require "fileutils"
require "tmpdir"
require "yaml"

require "bundler"

describe "utopia command" do
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
	
	REQUIRED_GEMS = ["bake", "bake-test", "sus", "covered", "rack-test", "sus-fixtures-async-http", "falcon", "net-smtp", "benchmark-http", "protocol-rack"]
	
	def install_packages(dir)
		gems_path = File.join(dir, "gems.rb")
		File.open(gems_path, "w") do |file|
			file.puts "source 'https://rubygems.org'"
			file.puts "gem 'utopia', path: #{utopia_path.dump}"
			REQUIRED_GEMS.each do |gem|
				file.puts "gem '#{gem}'"
			end
		end
		
		system("bundle", "config", "set", "path", "vendor/bundle", chdir: dir)
		system("bundle", "install", chdir: dir)
	end
	
	it "should generate sample site" do
		Dir.mktmpdir("test-site") do |dir|
			install_packages(dir)
			
			system("bundle", "exec", "bake", "utopia:site:create", chdir: dir, exception: true)
			
			expected_files = [".git", "gems.rb", "gems.locked", "readme.md", "bake.rb", "config.ru", "lib", "pages", "public", "test"]
			site_files = Dir.entries(dir)
			
			expected_files.each do |file|
				expect(site_files).to be(:include?, file)
			end
			
			expect(
				system("bundle", "exec", "bake", "test", chdir: dir)
			).to be == true
		end
	end
	
	it "should generate a sample server" do
		Dir.mktmpdir("test-server") do |dir|
			install_packages(dir)
			
			system("bundle", "exec", "bake", "utopia:server:create", chdir: dir, exception: true)
			expect(Dir.entries(dir)).to be(:include?, ".git")
			
			system("git", "config", "--local", "core.sharedRepository", "false", chdir: dir, exception: true)
			system("chmod", "-Rf", "g-x", ".git", chdir: dir, exception: true)
			system("rm", "-f", ".git/hooks/post-receive", chdir: dir, exception: true)
			
			environment = YAML.load_file(File.join(dir, "config/environment.yaml"))
			expect(environment).to be(:include?, "VARIANT")
			expect(environment).to be(:include?, "UTOPIA_SESSION_SECRET")
		end
	end
	
	it "should not trash the sample server during update" do
		Dir.mktmpdir("test-server") do |dir|
			install_packages(dir)
			
			system("bundle", "exec", "bake", "utopia:server:create", chdir: dir, exception: true)
			system("git", "config", "--local", "core.sharedRepository", "false", chdir: dir, exception: true)
			system("chmod", "-Rf", "g-x", ".git", chdir: dir, exception: true)
			system("rm", "-f", ".git/hooks/post-receive", chdir: dir, exception: true)
			
			# Run the server update command:
			system("bundle", "exec", "bake", "utopia:server:update", chdir: dir, exception: true)
			
			# Check a couple of files to make sure they have group read and write access after the update:
			Dir.glob(File.join(dir, ".git/**/*")).each do |path|
				expect(group_rw(path)).to be == true
			end
		end
	end
	
	it "can generate sample site, server and push to the server" do
		# This assumes your default branch is "main". We should probably be more flexible around this.
		# git config --global init.defaultBranch main
		Dir.mktmpdir("test") do |dir|
			site_path = File.join(dir, "site")
			FileUtils.mkdir_p(site_path)
			
			server_path = File.join(dir, "server")
			FileUtils.mkdir_p(server_path)
			
			install_packages(site_path)
			install_packages(server_path)
			
			system("bundle", "exec", "bake", "utopia:site:create", chdir: site_path, exception: true)
			system("bundle", "exec", "bake", "utopia:server:create", chdir: server_path, exception: true)
			
			system("git", "push", "--set-upstream", server_path, "main", chdir: site_path, exception: true)
			
			expected_files = %W[.git gems.rb gems.locked readme.md bake.rb config.ru lib pages public]
			server_files = Dir.entries(server_path)
			
			expected_files.each do |file|
				expect(server_files).to be(:include?, file)
			end
			
			expect(File.executable? File.join(server_path, "config.ru")).to be == true
			puts File.stat(File.join(dir, "server", ".git")).mode
		end
	end
end
