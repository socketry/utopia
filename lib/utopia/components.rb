# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2026, by Samuel Williams.

require "fileutils"
require "json"
require "pathname"

module Utopia
	# Installs JavaScript packages into the public components directory. Package contents are copied from `dist` when it exists, otherwise from the package root.
	#
	# By default, the complete source directory is installed. Projects can limit an individual package to a set of files using `utopia.components` in their `package.json` file.
	class Components
		# Initialize a component installer for the given project root.
		#
		# @parameter root [String | Pathname] The project root directory.
		def initialize(root)
			@root = Pathname.new(root)
			@package_root = @root + "node_modules"
			
			# This is a legacy path:
			unless @package_root.directory?
				@package_root = @root + "lib/components"
			end
			
			@install_root = @root + "public/_components"
			@configuration = load_configuration
		end
		
		# @attribute [Pathname] The directory containing the installed JavaScript packages.
		attr :package_root
		
		# Update the specified packages in the public components directory.
		#
		# @parameter package_names [Array(String)] The production package names to install.
		def update(package_names)
			expand_package_paths(@package_root).each do |package_path|
				package_name = package_path.relative_path_from(@package_root).to_s
				
				if package_names.include?(package_name)
					install(package_name, package_path)
				end
			end
		end
		
		private
		
		# Load the optional per-package installation rules. A missing `package.json`, or a file without `utopia.components`, preserves the default behaviour of copying complete packages.
		# @returns [Hash] The per-package installation rules.
		def load_configuration
			package_path = @root + "package.json"
			
			unless package_path.file?
				return {}
			end
			
			configuration = JSON.parse(package_path.read).dig("utopia", "components") || {}
			
			unless configuration.is_a?(Hash)
				raise ArgumentError, "utopia.components must be an object!"
			end
			
			return configuration
		end
		
		# Install one package. Distribution directories are preferred because they generally contain the browser-ready form of a package.
		# @parameter package_name [String] The package name relative to `node_modules`.
		# @parameter package_path [Pathname] The package source directory.
		def install(package_name, package_path)
			install_path = @install_root + package_name
			dist_path = package_path + "dist"
			
			if dist_path.directory?
				source_path = dist_path
			else
				source_path = package_path
			end
			
			configuration = @configuration[package_name]
			
			if configuration
				install_selected(package_name, source_path, install_path, configuration)
			else
				FileUtils::Verbose.rm_rf(install_path)
				FileUtils::Verbose.mkpath(install_path.dirname)
				FileUtils::Verbose.cp_r(source_path, install_path)
			end
		end
		
		# Install only the files matched by the configured include patterns. Every pattern is resolved before removing the existing installation, so an invalid configuration cannot leave a package partially installed or remove a previously working copy.
		# @parameter package_name [String] The package name relative to `node_modules`.
		# @parameter source_path [Pathname] The package source directory.
		# @parameter install_path [Pathname] The destination directory.
		# @parameter configuration [Hash] The package installation rules.
		def install_selected(package_name, source_path, install_path, configuration)
			unless configuration.is_a?(Hash)
				raise ArgumentError, "utopia.components.#{package_name}.include must be a non-empty array!"
			end
			
			include_patterns = configuration["include"]
			
			unless include_patterns.is_a?(Array) && include_patterns.any?
				raise ArgumentError, "utopia.components.#{package_name}.include must be a non-empty array!"
			end
			
			paths = include_patterns.flat_map do |pattern|
				included_paths(package_name, source_path, pattern)
			end.uniq.sort
			
			FileUtils::Verbose.rm_rf(install_path)
			
			paths.each do |relative_path|
				source_file = source_path + relative_path
				install_file = install_path + relative_path
				
				FileUtils::Verbose.mkpath(install_file.dirname)
				FileUtils::Verbose.cp(source_file, install_file)
			end
		end
		
		# Expand one include pattern into files relative to the package source. Directories are excluded so each result can be copied independently.
		# @parameter package_name [String] The package name used in validation errors.
		# @parameter source_path [Pathname] The package source directory.
		# @parameter pattern [String] The include pattern to expand.
		# @returns [Array(String)] The matching file paths relative to the package source.
		def included_paths(package_name, source_path, pattern)
			unless pattern.is_a?(String) && relative_pattern?(pattern)
				raise ArgumentError, "Invalid include pattern for #{package_name}: #{pattern.inspect}"
			end
			
			paths = Dir.glob(pattern, base: source_path.to_s).select do |relative_path|
				(source_path + relative_path).file?
			end
			
			if paths.empty?
				raise ArgumentError, "Include pattern for #{package_name} matched no files: #{pattern.inspect}"
			end
			
			return paths
		end
		
		# Determine whether the pattern is contained within the package source. Absolute paths and parent traversal are rejected because they could otherwise copy arbitrary files from outside the package.
		# @parameter pattern [String] The include pattern to validate.
		# @returns [Boolean] Whether the pattern is relative and does not contain parent traversal.
		def relative_pattern?(pattern)
			path = Pathname.new(pattern)
			
			if path.absolute?
				return false
			end
			
			if path.each_filename.any?{|component| component == ".."}
				return false
			end
			
			return true
		end
		
		# Enumerate packages in `node_modules`, descending through scoped package directories such as `@socketry` while preserving their scoped names.
		# @parameter root [Pathname] The directory to enumerate.
		# @parameter into [Array(Pathname)] The array into which package paths are appended.
		# @returns [Array(Pathname)] The discovered package directories.
		def expand_package_paths(root, into = [])
			root.children.select(&:directory?).each do |path|
				basename = path.basename.to_s
				
				# Handle organisation sub-directories which start with an '@' symbol:
				if basename.start_with?("@")
					expand_package_paths(path, into)
				else
					into << path
				end
			end
			
			return into
		end
	end
end
