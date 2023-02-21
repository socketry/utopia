# frozen_string_literal: true

require_relative "lib/utopia/version"

Gem::Specification.new do |spec|
	spec.name = "utopia"
	spec.version = Utopia::VERSION
	
	spec.summary = "Utopia is a framework for building dynamic content-driven websites."
	spec.authors = ["Samuel Williams", "Huba Nagy", "Michael Adams", "Olle Jonsson", "Pierre Montelle"]
	spec.license = "MIT"
	
	spec.cert_chain  = ['release.cert']
	spec.signing_key = File.expand_path('~/.gem/release.pem')
	
	spec.homepage = "https://github.com/ioquatix/utopia"
	
	spec.metadata = {
		"funding_uri" => "https://github.com/sponsors/ioquatix/",
	}
	
	spec.files = Dir.glob(['{bake,bin,lib,setup}/**/*', '*.md'], File::FNM_DOTMATCH, base: __dir__)
	
	spec.required_ruby_version = ">= 2.7"
	
	spec.add_dependency "concurrent-ruby", "~> 1.2"
	spec.add_dependency "console", "~> 1.0"
	spec.add_dependency "http-accept", "~> 2.1"
	spec.add_dependency "mail", "~> 2.6"
	spec.add_dependency "mime-types", "~> 3.0"
	spec.add_dependency "msgpack"
	spec.add_dependency "net-smtp"
	spec.add_dependency "rack", "~> 3.0"
	spec.add_dependency "samovar", "~> 2.1"
	spec.add_dependency "traces"
	spec.add_dependency "trenni", "~> 3.0"
	spec.add_dependency "variant", "~> 0.1"
	
	spec.add_development_dependency "async-websocket"
	spec.add_development_dependency "bake"
	spec.add_development_dependency "bundler"
	spec.add_development_dependency "covered"
	spec.add_development_dependency "falcon"
	spec.add_development_dependency "sus"
	spec.add_development_dependency "sus-fixtures-async-http"
end
