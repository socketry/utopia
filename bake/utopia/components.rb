# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2026, by Samuel Williams.

NPM = ENV["NPM"] || "npm"

# Update public components from production JavaScript packages.
#
# Packages are copied from their `dist` directory when present, or otherwise
# from the package root. The `utopia.components` section of `package.json` can
# specify per-package `include` patterns to select only required files.
#
# @parameter root [String] The project root directory.
def update(root: context.root)
	require "json"
	require "open3"
	require "utopia/components"
	
	components = Utopia::Components.new(root)
	production_packages = fetch_production_packages(components.package_root)
	
	components.update(production_packages)
end

private

def fetch_production_packages(package_root)
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
