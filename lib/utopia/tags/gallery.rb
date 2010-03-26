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

require 'utopia/tags'

require 'RMagick'
require 'fileutils'

class Utopia::Tags::Gallery
	PROCESSES = {
		:photo_thumbnail => lambda do |img|
			img = img.resize_to_fit(300, 300)

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
		:large => lambda{|img| img.resize_to_fit(768, 768)}
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
	
	def metadata
		metadata_path = @node.local_path(@path + "gallery.yaml")
		
		if File.exist? metadata_path
			return YAML::load(File.read(metadata_path))
		else
			return {}
		end
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
		
		if processes.kind_of? String
			processes = processes.split(",")
		end
		
		processes.each do |process|
			local_processed_path = @node.local_path(image_path.processed(process))
		
			unless File.exists? local_processed_path
				image = Magick::ImageList.new(local_original_path)

				processed_image = PROCESSES[process.to_sym].call(image)
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

		filter = Regexp.new(state["filter"]) if state["filter"]

		transaction.tag("div", "class" => "gallery") do |node|
			images = gallery.images(options).sort_by do |path|
				name = path.original.basename
				metadata[name]["order"] || name
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
