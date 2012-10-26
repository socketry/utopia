
require 'utopia/version'
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
				buffer = File.read(path).gsub('$UTOPIA_VERSION', Utopia::VERSION.dump)
				File.open(path, "w") { |file| file.write(buffer) }
			end
		end
	end
end