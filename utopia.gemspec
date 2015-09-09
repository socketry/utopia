# -*- encoding: utf-8 -*-
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'utopia/version'

Gem::Specification.new do |spec|
	spec.name          = "utopia"
	spec.version       = Utopia::VERSION
	spec.authors       = ["Samuel Williams"]
	spec.email         = ["samuel.williams@oriontransfer.co.nz"]
	spec.description   = <<-EOF
		Utopia is a website generation framework which provides a robust set of tools
		to build highly complex dynamic websites. It uses the filesystem heavily for
		content and provides frameworks for interacting with files and directories as
		structure representing the website.
	EOF
	spec.summary       = %q{Utopia is a framework for building dynamic content-driven websites.}
	spec.homepage      = "https://github.com/ioquatix/utopia"

	spec.files         = `git ls-files`.split($/)
	spec.executables   = spec.files.grep(%r{^bin/}).map{ |f| File.basename(f) }
	spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
	spec.require_paths = ["lib"]
	
	spec.add_dependency "trenni", "~> 1.4.1"
	spec.add_dependency "mime-types", "~> 2.0"
	
	spec.add_dependency "rack", "~> 1.6"
	spec.add_dependency "rack-cache", "~> 1.2.0"
	
	spec.add_dependency "mail", "~> 2.6.1"
	
	spec.add_development_dependency "bundler", "~> 1.3"
	spec.add_development_dependency "rspec", "~> 3.1.0"
	spec.add_development_dependency "puma"
	spec.add_development_dependency "rake"
end
