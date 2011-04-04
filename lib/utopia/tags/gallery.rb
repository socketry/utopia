#	This file is part of the "Utopia Framework" project, and is licensed under the GNU AGPLv3.
#	Copyright 2010 Samuel Williams. All rights reserved.
#	See <utopia.rb> for licensing details.

require 'utopia/tags'

require 'RMagick'
require 'fileutils'

class Utopia::Tags::Gallery
	module Processes
		class Thumbnail
			def initialize(size = [800, 800])
				@size = size
			end
			
			def call(img)
				# Only resize an image if it is bigger than the given size.
				if (img.columns > @size[0] || img.rows > @size[1])
					img.resize_to_fit(*@size)
				else
					img
				end
			end
			
			def default_extension(path)
				ext = path.original.extension
				
				case ext
				when /pdf/i
					return "png"
				else
					return ext.downcase
				end
			end
		end
		
		# Resize the image to fit within the specified dimensions while retaining the aspect ratio of the original image. If necessary, crop the image in the larger dimension.
		class CropThumbnail < Thumbnail
			def call(img)
				img.resize_to_fill(*@size)
			end
		end
		
		class DocumentThumbnail < Thumbnail
			def call(img)
				img = super(img)

				shadow = img.dup

				shadow = shadow.colorize(1, 1, 1, 'gray50')
				shadow.background_color = 'transparent'
				shadow.border!(10, 10, 'transparent')

				shadow = shadow.gaussian_blur_channel(5, 5, Magick::AlphaChannel)

				shadow.composite(img, 5, 5, Magick::OverCompositeOp)
			end
			
			def default_extension(path)
				return "png"
			end
		end

		class PhotoThumbnail < Thumbnail
			def call(img)
				img = super(img)

				shadow = img.dup

				shadow = shadow.colorize(1, 1, 1, '#999999ff')
				shadow.background_color = 'transparent'
				shadow.border!(10, 10, '#99999900')

				shadow = shadow.gaussian_blur_channel(5, 5, Magick::AlphaChannel)

				shadow.composite(img, 5, 5, Magick::OverCompositeOp)
			end
			
			def default_extension(path)
				return "png"
			end
		end
	end
	
	CACHE_DIR = "_cache"
	PROCESSES = {
		:pdf_thumbnail => Processes::DocumentThumbnail.new([300, 300]),
		:photo_thumbnail => Processes::PhotoThumbnail.new([300, 300]),
		:large => Processes::Thumbnail.new([800, 800]),
		:square_thumbnail => Processes::CropThumbnail.new([300, 300]),
		:thumbnail => Processes::Thumbnail.new([300, 300])
	}
	
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
	
	class ImageMetadata
		def initialize(metadata)
			@metadata = metadata
		end
		
		attr :metadata
		
		def [] (key)
			@metadata[key.to_s]
		end
		
		def to_s
			@metadata['caption'] || ''
		end
		
		# A bit of a hack to ease migration.
		def to_html
			to_s.to_html
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
		options[:filter] ||= /(jpg|png)$/i

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
		
		processes.each do |process_name, extension|
			process_name = process_name.to_sym
			
			process = PROCESSES[process_name]
			extension ||= process.default_extension(image_path)
			
			image_path.extensions[process_name] = extension if extension
			
			local_processed_path = @node.local_path(image_path.processed(process_name))
			
			unless File.exists? local_processed_path
				image = Magick::ImageList.new(local_original_path)
				image.scene = 0
				
				processed_image = process.call(image)
				processed_image.write(local_processed_path)
				
				# Run GC to free up any memory.
				processed_image = nil
				GC.start if defined? GC
			end
		end
	end
	
	def self.call(transaction, state)
		gallery = new(transaction.end_tags[-2].node, Utopia::Path.create(state["path"] || "./"))
		metadata = gallery.metadata
		metadata.default = {}

		tag_name = state["tag"] || "img"
		gallery_class = state["class"] || "gallery"

		options = {}
		options[:process] = state["process"]
		options[:filter] = Regexp.new("(#{state["filetypes"]})$", "i") if state["filetypes"]
		
		filter = Regexp.new(state["filter"], Regexp::IGNORECASE) if state["filter"]

		transaction.tag("div", "class" => gallery_class) do |node|
			images = gallery.images(options).sort do |a, b|
				if (metadata[a.original.basename]["order"] && metadata[b.original.basename]["order"])
					metadata[a.original.basename]["order"] <=> metadata[b.original.basename]["order"]
				else
					a.original.basename <=> b.original.basename
				end
			end

			images.each do |path|
				next if filter and !filter.match(path.original.basename)
				
				alt = ImageMetadata.new(metadata[path.original.basename])
				transaction.tag(tag_name, "src" => path, "alt" => alt)
			end
		end
	end
end

Utopia::Tags.register("gallery", Utopia::Tags::Gallery)
