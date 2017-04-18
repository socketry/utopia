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

require 'fileutils'
require 'tmpdir'
require 'yaml'

require 'open3'

RSpec.describe "utopia executable" do
	let(:utopia) {File.expand_path("../../bin/utopia", __dir__)}
	let(:gemspec) {Gem::Specification.load File.expand_path("../../utopia.gemspec", __dir__)}
	let(:package_path) {File.expand_path("../../pkg/#{gemspec.file_name}", __dir__)}
	
	before(:all) do
		# We need to build a package to test deployment:
		system("rake", "build") or abort("Could not build package for setup spec!")
		
		ENV['DEPLOY_USER'] = 'http'
		ENV['DEPLOY_GROUP'] = 'http'
	end
	
	around(:each) do |example|
		Bundler.with_clean_env do
			# If we don't delete this, when running on travis, it will try submit the coverage report.
			ENV.delete('COVERAGE')
			
			# This allows the utopia command to load the correct library:
			ENV['RUBYLIB'] = File.expand_path("../../lib", __dir__)
			
			example.run
		end
	end
	
	def sh_status(*args)
		system(*args) ? 0 : false
	end
	
	def sh_stdout(*args)
		output, status = Open3.capture2(*args)
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
		# We do a bit of a hack here to ensure the package is available:
		FileUtils.mkpath File.join(dir, "vendor/cache")
		FileUtils.cp package_path, File.join(dir, "vendor/cache")
	end
	
	it "should generate sample site" do
		Dir.mktmpdir('test-site') do |dir|
			install_packages(dir)
			
			result = sh_status(utopia, "--in", dir, "site", "create")
			expect(result).to be == 0
			
			expect(Dir.entries(dir)).to include(".bowerrc", ".git", "Gemfile", "Gemfile.lock", "README.md", "Rakefile", "config.ru", "lib", "pages", "public", "spec")
			
			Dir.chdir(dir) do
				result = sh_status("rake", "test")
				expect(result).to be == 0
			end
		end
	end
	
	it "should generate a sample server" do
		Dir.mktmpdir('test-server') do |dir|
			install_packages(dir)
			
			result = sh_status(utopia, "--in", dir, "server", "create")
			expect(result).to be == 0
			
			expect(Dir.entries(dir)).to include(".git")
			
			# make sure git is set up properly
			Dir.chdir(dir) do
				expect(git_config 'core.sharedRepository').to be == '1'
				expect(git_config 'receive.denyCurrentBranch').to be == 'ignore'
				expect(git_config 'core.worktree').to be == dir
			end
			
			environment = YAML.load_file(File.join(dir, 'config/environment.yaml'))
			expect(environment).to include('RACK_ENV', 'UTOPIA_SESSION_SECRET')
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
		Dir.mktmpdir('test') do |dir|
			site_path = File.join(dir, 'site')
			
			install_packages(site_path)
			
			server_path = File.join(dir, 'server')
			
			result = sh_status(utopia, "--in", site_path, "site", "create")
			expect(result).to be == 0
			
			result = sh_status(utopia, "--in", server_path, "server", "create")
			expect(result).to be == 0
			
			Dir.chdir(site_path) do
				result = sh_status("git", "push", "--set-upstream", server_path, "master")
				expect(result).to be == 0
			end
			
			files = %W[.bowerrc .git Gemfile Gemfile.lock README.md Rakefile config.ru lib pages public]
			
			expect(Dir.entries(server_path)).to include(*files)
			
			expect(File.executable? File.join(server_path, 'config.ru')).to be == true
			
			puts File.stat(File.join(dir, 'server', '.git')).mode
		end
	end
end
