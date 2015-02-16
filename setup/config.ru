#!/usr/bin/env rackup

# Setup default encoding:
Encoding.default_external = Encoding::UTF_8
Encoding.default_internal = Encoding::UTF_8

# Setup the server environment:
RACK_ENV = ENV.fetch('RACK_ENV', :development).to_sym unless defined?(RACK_ENV)

# Allow loading library code from lib directory:
$LOAD_PATH << File.expand_path("../lib", __FILE__)

require 'utopia'
require 'rack/cache'

if RACK_ENV == :production
	use Utopia::ExceptionHandler, "/errors/exception"
	use Utopia::MailExceptions
elsif RACK_ENV == :development
	use Rack::ShowExceptions
end

use Rack::Sendfile

if RACK_ENV == :production
	use Rack::Cache,
		metastore: "file:#{Utopia::default_root("cache/meta")}",
		entitystore: "file:#{Utopia::default_root("cache/body")}",
		verbose: RACK_ENV == :development
end

use Rack::ContentLength

use Utopia::Redirector,
	patterns: [
		Utopia::Redirector::DIRECTORY_INDEX
	],
	strings: {
		'/' => '/welcome/index',
	},
	errors: {
		404 => "/errors/file-not-found"
	}

use Utopia::Localization,
	:default_locale => 'en',
	:locales => ['en', 'de', 'ja', 'zh'],
	:nonlocalized => ['/_static/', '/_cache/']

use Utopia::Controller,
	cache_controllers: (RACK_ENV == :production)

use Utopia::Static

use Utopia::Content,
	cache_templates: (RACK_ENV == :production),
	tags: {
		'deferred' => Utopia::Tags::Deferred,
		'override' => Utopia::Tags::Override,
		'node' => Utopia::Tags::Node,
		'environment' => Utopia::Tags::Environment.for(RACK_ENV)
	}

run lambda { |env| [404, {}, []] }
