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

RSpec.describe "utopia executable" do
	let(:utopia) {File.expand_path("../../bin/utopia", __dir__)}
	
	before(:all) do
		# We need to build a package to test deployment:
		system("rake", "build") or abort("Could not build package for setup spec!")
		
		ENV.delete 'BUNDLE_BIN_PATH'
		ENV.delete 'BUNDLE_GEMFILE'
		ENV.delete 'RUBYOPT'
	end
	
	def sh(*args)
		puts args.join(' ')
		system(*args)
		return $?
	end
	
	def install_packages(dir)
		package_path = File.expand_path("../../pkg/utopia-#{Utopia::VERSION}.gem", __dir__)
		
		# We do a bit of a hack here to ensure the package is available:
		FileUtils.mkpath File.join(dir, "vendor/cache")
		FileUtils.cp package_path, File.join(dir, "vendor/cache")
	end
	
	it "should generate sample site" do
		Dir.mktmpdir('test-site') do |dir|
			install_packages(dir)
			
			result = sh(utopia, "--in", dir, "site", "create")
			expect(result).to be == 0
			
			expect(Dir.entries(dir)).to include(".bowerrc", ".git", "Gemfile", "Gemfile.lock", "README.md", "Rakefile", "cache", "config.ru", "lib", "pages", "public", "tmp")
		end
	end
	
	it "should generate a sample server" do
		Dir.mktmpdir('test-server') do |dir|
			install_packages(dir)
			
			result = sh(utopia, "--in", dir, "server", "create")
			expect(result).to be == 0
			
			expect(Dir.entries(dir)).to include(".git")
		end
	end
	
	it "can generate sample site, server and push to the server" do
		Dir.mktmpdir('test') do |dir|
			site_path = File.join(dir, 'site')
			
			install_packages(site_path)
			
			server_path = File.join(dir, 'server')
			
			result = sh(utopia, "--in", site_path, "site", "create")
			expect(result).to be == 0
			
			result = sh(utopia, "--in", server_path, "server", "create")
			expect(result).to be == 0
			
			Dir.chdir(site_path) do
				result = sh("git", "push", "--set-upstream", server_path, "master")
				expect(result).to be == 0
			end
			
			expect(Dir.entries(server_path)).to include(".bowerrc", ".git", "Gemfile", "README.md", "Rakefile", "cache", "config.ru", "lib", "pages", "public", "tmp")
		end
	end
end
