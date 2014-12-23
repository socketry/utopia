# Copyright, 2012, by Samuel G. D. Williams. <http://www.codeotaku.com>
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

require_relative 'version'

require 'fileutils'
require 'find'
require 'rake'

module Utopia
	module Setup
		ROOT = File.join(File.dirname(__FILE__), "setup", "")
		DIRECTORIES = ["access_log", "cache", "cache/meta", "cache/body", "lib", "pages", "public"]
		
		def self.copy(to, config = {})
			$stderr.puts "Copying files from #{ROOT} to #{to}..."
			Find.find(ROOT) do |src|
				dst = File.join(to, src[ROOT.size..-1])
				
				if File.directory?(src)
					FileUtils.mkdir_p(dst)
				else
					if File.exist? dst
						$stderr.puts "File already exists: #{dst}!"
					else
						$stderr.puts "Copying #{src} to #{dst}..."
						FileUtils.cp(src, dst)
					end
				end
			end
			
			DIRECTORIES.each do |path|
				FileUtils.mkdir_p(File.join(to, path))
			end
			
			['config.ru', 'Gemfile'].each do |configuration_file|
				$stderr.puts "Updating #{configuration_file}..."
				path = File.join(to, configuration_file)
				buffer = File.read(path).gsub('$UTOPIA_VERSION', Utopia::VERSION)
				File.open(path, "w") { |file| file.write(buffer) }
			end
		end
	end
end