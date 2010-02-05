
# Copied from Innate. Thanks manveru ^_^

require 'digest/md5'

module Utopia

	class Etanni
		SEPARATOR = Digest::MD5.hexdigest(Time.new.to_s)
		START = "\n_out_ << <<#{SEPARATOR}.chomp!\n"
		STOP = "\n#{SEPARATOR}\n"
		REPLACEMENT = "#{STOP}\\1#{START}"

		def initialize(template, compiled = false)
			if compiled
				@compiled = template
			else
				@template = template
				compile!
			end
		end

		def compile!
			temp = @template.dup
			temp.strip!
			temp.gsub!(/<\?r\s+(.*?)\s+\?>/m, REPLACEMENT)
			@compiled = "_out_ = [<<#{SEPARATOR}.chomp!]\n#{temp}#{STOP}_out_"
		end

		def result(binding, filename = '<Etanni>')
			eval(@compiled, binding, filename).join
		end
		
		attr :compiled
	end
	
	class TemplateCache
		CACHE_PREFIX = ".cache."
		CACHE_ENABLED = true
		
		def self.cache_path(path)
			File.join(File.dirname(path), CACHE_PREFIX + File.basename(path))
		end
		
		def self.mtime(path)
			File.symlink?(path) ? File.lstat(file_name).mtime : File.mtime(path)
		end
		
		def initialize(path, template_class = Etanni)
			@path = path
			@cache_path = TemplateCache.cache_path(@path)
			
			if !File.exist?(@cache_path) || (TemplateCache.mtime(@path) > TemplateCache.mtime(@cache_path))
				@template = template_class.new(File.read(@path))
				File.open(@cache_path, "w") { |f| f.write(@template.compiled) }
			else
				@template = template_class.new(File.read(@cache_path), true)
			end
		end
		
		def result(binding)
			@template.result(binding, @cache_path)
		end
	end
end