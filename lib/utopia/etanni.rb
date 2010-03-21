# Copyright (c) 2010 Samuel Williams. Released under the GNU GPLv3.
#
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
# 
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
# 
# You should have received a copy of the GNU General Public License
# along with this program.  If not, see <http://www.gnu.org/licenses/>.

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