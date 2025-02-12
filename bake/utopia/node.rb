# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2016-2025, by Samuel Williams.

NPM = ENV["NPM"] || "npm"

def update
	require "fileutils"
	require "utopia/path"
	
	root = Pathname.new(context.root)
	package_root = root + "node_modules"
	
	# This is a legacy path:
	unless package_root.directory?
		package_root = root + "lib/components"
	end
	
	install_root = root + "public/_components"
	
	# Fetch only production dependencies using `npm ls --production`
	production_packages = fetch_production_packages(package_root)
	package_paths = expand_package_paths(package_root).select do |path|
		production_packages.include?(path.basename.to_s)
	end
	
	package_paths.each do |package_path|
		package_directory = package_path.relative_path_from(package_root)
		install_path = install_root + package_directory
		
		dist_path = package_path + "dist"
		
		FileUtils::Verbose.rm_rf(install_path)
		FileUtils::Verbose.mkpath(install_path.dirname)
		
		# If a package has a dist directory, we only symlink that... otherwise we have to do the entire package, and hope that bower's ignore was setup correctly:
		if dist_path.exist?
			link_path = Utopia::Path.shortest_path(dist_path, install_path)
		else
			link_path = Utopia::Path.shortest_path(package_path, install_path)
		end
		
		FileUtils::Verbose.cp_r File.expand_path(link_path, install_path), install_path
	end
end

private

def fetch_production_packages(package_root)
	require "json"
	require "open3"
	
	stdout, _status = Open3.capture2(NPM, "ls", "--production", "--json", chdir: package_root.to_s)
	
	json = JSON.parse(stdout)
	
	flatten_package_dependencies(json).sort.uniq
end

def flatten_package_dependencies(json, into = [])
	if json["dependencies"]
		json["dependencies"].each do |name, details|
			into << name
			flatten_package_dependencies(details, into)
		end
	end
	
	return into
end

def expand_package_paths(root, into = [])
	paths = root.children.select(&:directory?)
	
	paths.each do |path|
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
