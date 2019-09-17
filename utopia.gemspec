
require_relative 'lib/utopia/version'

Gem::Specification.new do |spec|
	spec.name          = 'utopia'
	spec.version       = Utopia::VERSION
	spec.authors       = ['Samuel Williams']
	spec.email         = ['samuel.williams@oriontransfer.co.nz']
	spec.description   = <<-EOF
		Utopia is a website generation framework which provides a robust set of tools
		to build highly complex dynamic websites. It uses the filesystem heavily for
		content and provides frameworks for interacting with files and directories as
		structure representing the website.
	EOF
	spec.summary       = %q{Utopia is a framework for building dynamic content-driven websites.}
	spec.homepage      = 'https://github.com/ioquatix/utopia'
	spec.license       = "MIT"
	
	spec.files         = `git ls-files`.split($/)
	spec.executables   = spec.files.grep(%r{^bin/}).map{ |f| File.basename(f) }
	spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
	spec.require_paths = ['lib']
	
	spec.required_ruby_version = '~> 2.2'
	
	spec.add_dependency 'trenni', '~> 3.0'
	spec.add_dependency 'mime-types', '~> 3.0'
	spec.add_dependency 'msgpack'
	
	spec.add_dependency 'samovar', '~> 2.1'
	spec.add_dependency 'console', '~> 1.0'
	
	spec.add_dependency 'rack', '~> 2.0'
	
	spec.add_dependency 'http-accept', '~> 2.1'
	
	spec.add_dependency 'mail', '~> 2.6'
	
	spec.add_dependency 'concurrent-ruby', '~> 1.0'
	
	spec.add_development_dependency 'falcon'
	spec.add_development_dependency 'async-rspec'
	spec.add_development_dependency 'async-websocket'
	
	spec.add_development_dependency 'covered'
	spec.add_development_dependency 'bundler'
	spec.add_development_dependency 'rspec', '~> 3.6'
	spec.add_development_dependency 'rake'
end
