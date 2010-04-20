#	This file is part of the "Utopia Framework" project, and is licensed under the GNU AGPLv3.
#	Copyright 2010 Samuel Williams. All rights reserved.
#	See <utopia.rb> for licensing details.

# [Etanni] Copyright (c) 2008 Michael Fellinger <m.fellinger@gmail.com>
#  
# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to
# deal in the Software without restriction, including without limitation the
# rights to use, copy, modify, merge, publish, distribute, sublicense, and/or
# sell copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:
#  
# The above copyright notice and this permission notice shall be included in
# all copies or substantial portions of the Software.
#  
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL
# THE AUTHORS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER 
# IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN
# CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.

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