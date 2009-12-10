
require 'utopia/tags'

require 'RMagick'
require 'fileutils'

class Utopia::Tags::Gallery
	PROCESSES = {
		:photo_thumbnail => lambda do |img|
			img = img.resize_to_fit(300, 300).border(2, 2, "gray50")

			shadow = img.flop
			shadow = shadow.colorize(1, 1, 1, "gray50")
			shadow.background_color = "white"
			shadow.border!(10, 10, "white")
			shadow = shadow.blur_image(0, 5)
      
			shadow.composite(img, 5, 5, Magick::OverCompositeOp)
		end,
		:thumbnail => lambda do |img| 
			img = img.resize_to_fit(300, 300)
		end,
		:large => lambda{|img| img.resize(1024, 1024)}
	}
	
	CACHE_DIR = "_cache"
	
	class ImagePath
		def initialize(original_path)
			@original_path = original_path
			@cache_root = @original_path.dirname + CACHE_DIR
		end

		attr :cache_root

		def original
			@original_path
		end

		def self.append_suffix(name, suffix)
			name.split(".").insert(-2, suffix).join(".")
		end

		def processed(process = nil)
			if process
				name = @original_path.basename
				return cache_root + ImagePath.append_suffix(name, process.to_s)
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
		
		Utopia::LOG.debug("node: #{node.inspect} path: #{path}")
	end
	
	def images(options = {})
		options[:filter] ||= /(\.jpg|\.png)$/

		paths = []
		local_path = @node.local_path(@path)

		Utopia::LOG.debug("Scanning #{local_path}")

		Dir.entries(local_path).each do |filename|
			next unless filename.match(options[:filter])

			Utopia::LOG.debug("Filename #{filename} matched filter...")

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
		
		unless processes.respond_to? :each
			processes = processes.split(",")
		end
		
		processes.each do |process|
			local_processed_path = @node.local_path(image_path.processed(process))
		
			#unless File.exists? local_processed_path
				image = Magick::ImageList.new(local_original_path)

				processed_image = PROCESSES[process.to_sym].call(image)
				processed_image.write(local_processed_path)
			#end
		end
	end
	
	def self.call(transaction, state)
		gallery = new(transaction.end_tags[-2].node, Utopia::Path.create(state["path"] || "./"))
		tag_name = state["tag"] || "img"

		options = {}
		options[:process] = state["process"]

		transaction.tag("div", "class" => "gallery") do |node|
			gallery.images(options).each do |path|
				transaction.tag(tag_name, "src" => path)
			end
		end
	end
end

Utopia::Tags.register("gallery", Utopia::Tags::Gallery)
