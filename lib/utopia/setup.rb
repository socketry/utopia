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
		ROOT = File.expand_path("../setup", __FILE__)
		DIRECTORIES = ["cache", "cache/meta", "cache/body", "lib", "pages", "public"]
		SYMLINKS = {"public/_static" => "../pages/_static"}
		
		def self.copy(destination, config = {})
			$stderr.puts "Copying files from #{ROOT} to #{destination}..."
			
			DIRECTORIES.each do |directory|
				FileUtils.mkdir_p(File.join(destination, directory))
			end
			
			Find.find(ROOT) do |source_path|
				destination_path = File.join(destination, source_path[ROOT.size..-1])
				
				if File.directory?(source_path)
					FileUtils.mkdir_p(destination_path)
				else
					if File.exist? destination_path
						$stderr.puts "\tFile already exists: #{destination_path}!"
					else
						$stderr.puts "\tCopying #{source_path} to #{destination_path}..."
						FileUtils.copy_entry(source_path, destination_path)
					end
				end
			end
			
			SYMLINKS.each do |path, target|
				FileUtils.ln_s(target, File.join(destination, path))
			end
			
			['config.ru', 'Gemfile'].each do |configuration_file|
				path = File.join(destination, configuration_file)
				$stderr.puts "Updating #{path}..."
				buffer = File.read(path).gsub('$UTOPIA_VERSION', Utopia::VERSION)
				File.open(path, "w") { |file| file.write(buffer) }
			end
		end
	end
end