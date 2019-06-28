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

require 'mime/types'

module Utopia
	# A middleware which serves static files from the specified root directory.
	class Static
		# Default mime-types which are common for files served over HTTP:
		MIME_TYPES = {
			:xiph => {
				"ogx" => "application/ogg",
				"ogv" => "video/ogg",
				"oga" => "audio/ogg",
				"ogg" => "audio/ogg",
				"spx" => "audio/ogg",
				"flac" => "audio/flac",
				"anx" => "application/annodex",
				"axa" => "audio/annodex",
				"xspf" => "application/xspf+xml",
			},
			:media => [
				:xiph, "mp3", "mp4", "wav", "aiff", ["aac", "audio/x-aac"], "mov", "avi", "wmv", "mpg"
			],
			:text => [
				"html", "css", "js", ["map", "application/json"], "txt", "rtf", "xml", "pdf"
			],
			:fonts => [
				"otf", ["eot", "application/vnd.ms-fontobject"], "ttf", "woff", "woff2"
			],
			:archive => [
				"zip", "tar", "tgz", "tar.gz", "tar.bz2", ["dmg", "application/x-apple-diskimage"],
				["torrent", "application/x-bittorrent"]
			],
			:images => [
				"png", "gif", "jpeg", "tiff", "svg"
			],
			:default => [
				:media, :text, :archive, :images, :fonts
			]
		}
		
		# A class to assist with loading mime-type metadata.
		class MimeTypeLoader
			def initialize(library)
				@extensions = {}
				@library = library
			end
			
			attr :extensions
			
			def self.extensions_for(types, library = MIME_TYPES)
				loader = self.new(library)
				loader.expand(types)
				return loader.extensions
			end
			
			def extract_extensions(mime_types)
				mime_types.select{|mime_type| !mime_type.obsolete?}.each do |mime_type|
					mime_type.extensions.each do |ext|
						@extensions["." + ext] = mime_type.content_type
					end
				end
			end
			
			class ExpansionError < ArgumentError
			end
			
			def expand(types)
				types.each do |type|
					current_count = @extensions.size
					
					begin
						case type
						when Symbol
							self.expand(MIME_TYPES[type])
						when Array
							@extensions["." + type[0]] = type[1]
						when String
							self.extract_extensions MIME::Types.of(type)
						when Regexp
							self.extract_extensions MIME::Types[type]
						when MIME::Type
							self.extract_extensions.call([type])
						end
					rescue
						raise ExpansionError.new("#{self.class.name}: Error while processing #{type.inspect}!")
					end
					
					if @extensions.size == current_count
						raise ExpansionError.new("#{self.class.name}: Could not find any mime type for #{type.inspect}")
					end
				end
			end
		end
	end
end
