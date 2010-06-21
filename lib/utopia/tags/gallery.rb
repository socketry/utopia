#	This file is part of the "Utopia Framework" project, and is licensed under the GNU AGPLv3.
#	Copyright 2010 Samuel Williams. All rights reserved.
#	See <utopia.rb> for licensing details.

require 'utopia/tags'

require 'RMagick'
require 'fileutils'

class Utopia::Tags::Gallery
	module Processes
		def self.pdf_thumbnail(img)
			img = img.resize_to_fit(300, 300)

			shadow = img.dup
			
			shadow = shadow.colorize(1, 1, 1, 'gray50')
			shadow.background_color = 'transparent'
			shadow.border!(10, 10, 'transparent')
			
			shadow = shadow.gaussian_blur_channel(5, 5, Magick::AlphaChannel)
      
			shadow.composite(img, 5, 5, Magick::OverCompositeOp)
		end

		def self.photo_thumbnail(img)
			img = img.resize_to_fit(300, 300)

			shadow = img.dup
			
			shadow = shadow.colorize(1, 1, 1, '#999999ff')
			shadow.background_color = 'transparent'
			shadow.border!(10, 10, '#99999900')
			
			shadow = shadow.gaussian_blur_channel(5, 5, Magick::AlphaChannel)
      
			shadow.composite(img, 5, 5, Magick::OverCompositeOp)
		end
		
		def self.thumbnail(img)
			img = img.resize_to_fit(300, 300)
		end
		
		def self.large(img)
			img.resize_to_fit(768, 768)
		end
	end
	
	CACHE_DIR = "_cache"
	
	class ImagePath
		def initialize(original_path)
			@original_path = original_path
			@cache_root = @original_path.dirname + CACHE_DIR
			
			@extensions = {}
		end

		attr :cache_root
		attr :extensions

		def original
			@original_path
		end

		def self.append_suffix(name, suffix, extension = nil)
			components = name.split(".")
			
			components.insert(-2, suffix)
			
			if (extension)
				components[-1] = extension
			end
			
			return components.join(".")
		end

		def processed(process = nil)
			if process
				name = @original_path.basename
				return cache_root + ImagePath.append_suffix(name, process.to_s, @extensions[process.to_sym])
			else
				return @original_path
			end
		end
		
		def to_html(process = nil)
			Tag.new("img", {"src" => path(process)}).to_html
		end
		
		def to_s
			@original_path.to_s
		end
		
		def method_missing(name, *args)
			return processed(name.to_s)
		end
	end
	
	def initialize(node, path)
		@node = node
		@path = path
	end
	
	def metadata
		metadata_path = @node.local_path(@path + "gallery.yaml")
		
		if File.exist? metadata_path
			return YAML::load(File.read(metadata_path))
		else
			return {}
		end
	end
	
	def images(options = {})
		options[:filter] ||= /(jpg|png)$/

		paths = []
		local_path = @node.local_path(@path)

		Dir.entries(local_path).each do |filename|
			next unless filename.match(options[:filter])

			fullpath = File.join(local_path, filename)

			paths << ImagePath.new(@path + filename)
		end

		if options[:process]
			paths.each do |path|
				processed_image(path, options[:process])
			end
		end

		return paths
	end
	
	def processed_image(image_path, processes)
		# Create the local cache directory if it doesn't exist already
		local_cache_path = @node.local_path(image_path.cache_root)
		
		unless File.exist? local_cache_path
			FileUtils.mkdir local_cache_path
		end
		
		# Calculate the new name for the processed image
		local_original_path = @node.local_path(image_path.original)
		
		if processes.kind_of? String
			processes = processes.split(",").collect{|p| p.split(":")}
		end
		
		processes.each do |process, extension|
			process = process.to_sym
			image_path.extensions[process] = extension if extension
			
			local_processed_path = @node.local_path(image_path.processed(process))
		
			unless File.exists? local_processed_path
				image = Magick::ImageList.new(local_original_path)
				image.scene = 0
				
				processed_image = Processes.send(process, image)
				processed_image.write(local_processed_path)
			end
		end
	end
	
	def self.call(transaction, state)
		gallery = new(transaction.end_tags[-2].node, Utopia::Path.create(state["path"] || "./"))
		metadata = gallery.metadata
		metadata.default = {}

		tag_name = state["tag"] || "img"

		options = {}
		options[:process] = state["process"]
		options[:filter] = Regexp.new("(#{state["filetypes"]})$") if state["filetypes"]
		
		filter = Regexp.new(state["filter"]) if state["filter"]

		transaction.tag("div", "class" => "gallery") do |node|
			images = gallery.images(options).sort do |a, b|
				if (metadata[a.original.basename]["order"] && metadata[b.original.basename]["order"])
					metadata[a.original.basename]["order"] <=> metadata[b.original.basename]["order"]
				else
					a.original.basename <=> b.original.basename
				end
			end

			images.each do |path|
				next if filter and !filter.match(path.original.basename)

				alt_text = metadata[path.original.basename]["caption"]
				transaction.tag(tag_name, "src" => path, "alt" => alt_text)
			end
		end
	end
end

Utopia::Tags.register("gallery", Utopia::Tags::Gallery)
