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

RSpec.describe "utopia tool" do
	let(:utopia) {File.expand_path("../../bin/utopia", __dir__)}
	
	before(:all) do
		sh("rake", "build")
		
		ENV.delete 'BUNDLE_BIN_PATH'
		ENV.delete 'BUNDLE_GEMFILE'
		ENV.delete 'RUBYOPT'
	end
	
	def sh(*args)
		puts args.join(' ')
		system(*args)
		return $?
	end
	
	it "should generate sample site" do
		Dir.mktmpdir('test-site') do |dir|
			# We do a bit of a hack here to ensure the package is available:
			FileUtils.mkpath File.join(dir, "vendor/cache")
			FileUtils.cp "pkg/utopia-#{Utopia::VERSION}.gem", File.join(dir, "vendor/cache")
			
			result = sh(utopia, "create", dir)
			expect(result).to be == 0
			
			expect(Dir.entries(dir)).to include(".bowerrc", ".git", "Gemfile", "Gemfile.lock", "README.md", "Rakefile", "cache", "config.ru", "lib", "pages", "public", "tmp")
		end
	end
	
	it "should generate a sample server" do
		Dir.mktmpdir('test-server') do |dir|
			FileUtils.mkpath File.join(dir, "vendor/cache")
			FileUtils.cp "pkg/utopia-#{Utopia::VERSION}.gem", File.join(dir, "vendor/cache")
			
			result = sh(utopia, "server:create", dir)
			expect(result).to be == 0
			
			expect(Dir.entries(dir)).to include(".git")
		end
	end
	
	it "can generate sample site, server and push to the server" do
		Dir.mktmpdir('test') do |dir|
			site_path = File.join(dir, 'site')
			
			FileUtils.mkpath File.join(site_path, "vendor/cache")
			FileUtils.cp "pkg/utopia-#{Utopia::VERSION}.gem", File.join(site_path, "vendor/cache")
			
			server_path = File.join(dir, 'server')
			
			result = sh(utopia, "create", site_path)
			expect(result).to be == 0
			
			result = sh(utopia, "server:create", server_path)
			expect(result).to be == 0
			
			Dir.chdir(site_path) do
				result = sh("git", "push", "--set-upstream", server_path, "master")
				expect(result).to be == 0
			end
			
			expect(Dir.entries(server_path)).to include(".bowerrc", ".git", "Gemfile", "README.md", "Rakefile", "cache", "config.ru", "lib", "pages", "public", "tmp")
		end
	end
end
