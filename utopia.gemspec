# -*- encoding: utf-8 -*-
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'utopia/version'

Gem::Specification.new do |gem|
  gem.name          = "utopia"
  gem.version       = Utopia::VERSION
  gem.authors       = ["Samuel Williams"]
  gem.email         = ["samuel.williams@oriontransfer.co.nz"]
  gem.description   = <<-EOF
  Utopia is a website generation framework which provides a robust set of tools
  to build highly complex dynamic websites. It uses the filesystem heavily for
  content and provides frameworks for interacting with files and directories as
  structure representing the website.
  EOF
  gem.summary       = %q{Utopia is a framework for building dynamic content-driven websites.}
  gem.homepage      = ""

  gem.files         = `git ls-files`.split($/)
  gem.executables   = gem.files.grep(%r{^bin/}).map{ |f| File.basename(f) }
  gem.test_files    = gem.files.grep(%r{^(test|spec|features)/})
  gem.require_paths = ["lib"]
  
  gem.add_dependency "trenni", "~> 1.2.0"
  gem.add_dependency "mime-types"
  gem.add_dependency "rack", "~> 1.4.1"
  
  gem.add_dependency "rack-cache"
  gem.add_dependency "rack-contrib"
end
