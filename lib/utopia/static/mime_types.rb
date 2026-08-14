# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2017-2026, by Samuel Williams.

require "protocol/media/registry"

module Utopia
	# A middleware which serves static files from the specified root directory.
	module Static
		# Default mime-types which are common for files served over HTTP:
		MIME_TYPES = {
			:xiph => [
				"ogx", "ogv", "oga", "ogg", "spx", "flac", "xspf"
			],
			:media => [
				:xiph, "mp3", "mp4", "wav", "aiff", "aac", "webm", "weba", "mov", "avi", "wmv", "mpg", "m3u8", "ts"
			],
			:text => [
				"html", "css", "js", "mjs", "map", "txt", "rtf", "xml", "pdf"
			],
			:fonts => [
				"otf", "eot", "ttf", "woff", "woff2"
			],
			:archive => [
				"zip", "tar", "tgz", "gz", "bz2", "dmg", "torrent"
			],
			:images => [
				"png", "gif", "jpeg", "tiff", "svg", "webp"
			],
			:default => [
				:media, :text, :archive, :images, :fonts, "wasm"
			]
		}
		
		# A class to assist with loading mime-type metadata.
		class MimeTypeLoader
			# Initialize an empty extension map backed by named MIME type groups.
			# @parameter library [Object] The library.
			def initialize(library)
				@extensions = {}
				@library = library
			end
			
			attr :extensions
			
			# Find extensions associated with the given MIME types.
			# @parameter types [Array] The MIME type definitions to expand.
			# @parameter library [Hash] The named MIME type groups.
			# @returns [Hash(String, String)] A mapping from file extensions to content types.
			def self.extensions_for(types, library = MIME_TYPES)
				loader = self.new(library)
				loader.expand(types)
				return loader.extensions
			end
			
			# Add an extension using its registered media type.
			# @parameter extension [String] The file extension.
			# @returns [Protocol::Media::Registry::Record] The registered media type record.
			def add_extension(extension)
				# Normalize optional leading dots and case before constructing the File.extname-style key:
				extension = extension.delete_prefix(".").downcase
				
				if record = Protocol::Media::Registry.for_extension(extension)
					@extensions["." + extension] = record.type.to_s
					return record
				end
				
				raise ExpansionError.new("Unknown file extension: #{extension.inspect}")
			end
			
			# Raised when expansion processing fails.
			class ExpansionError < ArgumentError
			end
			
			# Expand named groups, file extensions, and explicit extension pairs into extension mappings.
			# @parameter types [Array] The MIME type definitions.
			# @returns [Array] The supplied definitions.
			# @raises [ExpansionError] If a definition cannot be expanded.
			def expand(types)
				types.each do |type|
					case type
					when Symbol
						self.expand(@library.fetch(type))
					when Array
						@extensions["." + type[0]] = type[1]
					when String
						self.add_extension(type)
					else
						raise ExpansionError.new("Unsupported MIME type definition: #{type.inspect}")
					end
				rescue ExpansionError
					raise
				rescue
					raise ExpansionError.new("#{self.class.name}: Error while processing #{type.inspect}!")
				end
			end
		end
	end
end
