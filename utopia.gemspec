# frozen_string_literal: true

require_relative "lib/utopia/version"

Gem::Specification.new do |spec|
	spec.name = "utopia"
	spec.version = Utopia::VERSION
	
	spec.summary = "Utopia is a framework for building dynamic content-driven websites."
	spec.authors = ["Samuel Williams", "Huba Nagy", "Matt Quinn", "Michael Adams", "Olle Jonsson", "Pierre Montelle"]
	spec.license = "MIT"
	
	spec.cert_chain  = ["release.cert"]
	spec.signing_key = File.expand_path("~/.gem/release.pem")
	
	spec.homepage = "https://github.com/socketry/utopia"
	
	spec.metadata = {
		"documentation_uri" => "https://socketry.github.io/utopia/",
		"funding_uri" => "https://github.com/sponsors/ioquatix/",
		"source_code_uri" => "https://github.com/socketry/utopia.git",
	}
	
	spec.files = Dir.glob(["{bake,context,lib,setup}/**/*", "*.md"], File::FNM_DOTMATCH, base: __dir__)
	
	spec.required_ruby_version = ">= 3.2"
	
	spec.add_dependency "bake", "~> 0.20"
	spec.add_dependency "concurrent-ruby", "~> 1.2"
	spec.add_dependency "console", "~> 1.24"
	spec.add_dependency "http-accept", "~> 2.1"
	spec.add_dependency "irb"
	spec.add_dependency "mail", "~> 2.6"
	spec.add_dependency "mime-types", "~> 3.0"
	spec.add_dependency "msgpack"
	spec.add_dependency "net-smtp"
	spec.add_dependency "rack", "~> 3.0"
	spec.add_dependency "samovar", "~> 2.1"
	spec.add_dependency "traces", "~> 0.10"
	spec.add_dependency "variant", "~> 0.1"
	spec.add_dependency "xrb", "~> 0.4"
end
