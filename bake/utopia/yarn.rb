# frozen_string_literal: true

# Copy all installed JavaScript components to the public root.
def update
	require 'fileutils'
	require 'utopia/path'
	
	yarn_package_root = Pathname.new(context.root) + "lib/components"
	yarn_install_root = Pathname.new(context.root) + "public/_components"
	
	yarn_package_root.children.select(&:directory?).collect(&:basename).each do |package_directory|
		install_path = yarn_install_root + package_directory
		package_path = yarn_package_root + package_directory
		dist_path = package_path + 'dist'
		
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
