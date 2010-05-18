
require 'utopia/version'
require 'fileutils'
require 'find'
require 'rake'

module Utopia
	module Setup
		ROOT = File.join(File.dirname(__FILE__), "setup", "")
		DIRECTORIES = ["access_log", "cache", "cache/meta", "cache/head", "lib", "pages", "public"]
		
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
			
			$stderr.puts "Updating config.ru..."
			config_ru = File.join(to, "config.ru")
			buf = File.read(config_ru).gsub('$UTOPIA_VERSION', Utopia::VERSION::STRING.dump)
			File.open(config_ru, "w") { |fp| fp.write(buf) }
		end
	end
end