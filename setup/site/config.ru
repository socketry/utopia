#!/usr/bin/env rackup

# Setup default encoding:
Encoding.default_external = Encoding::UTF_8
Encoding.default_internal = Encoding::UTF_8

# Setup the server environment:
RACK_ENV = ENV.fetch('RACK_ENV', :development).to_sym unless defined?(RACK_ENV)

# Allow loading library code from lib directory:
$LOAD_PATH << File.expand_path("lib", __dir__)

require 'utopia'
require 'rack/cache'

if RACK_ENV == :production
	# Handle exceptions in production with a error page and send an email notification:
	use Utopia::Exceptions::Handler
	use Utopia::Exceptions::Mailer
else
	# We want to propate exceptions up when running tests:
	use Rack::ShowExceptions unless RACK_ENV == :test
	
	# Serve the public directory in a similar way to the web server:
	use Utopia::Static, root: 'public'
end

use Rack::Sendfile

if RACK_ENV == :production
	# Cache dynamically generated content where possible:
	use Rack::Cache,
		metastore: "file:#{Utopia::default_root("cache/meta")}",
		entitystore: "file:#{Utopia::default_root("cache/body")}",
		verbose: RACK_ENV == :development
end

use Utopia::ContentLength

use Utopia::Redirection::Rewrite,
	'/' => '/welcome/index'

use Utopia::Redirection::DirectoryIndex

use Utopia::Redirection::Errors,
	404 => '/errors/file-not-found'

use Utopia::Localization,
	:default_locale => 'en',
	:locales => ['en', 'de', 'ja', 'zh'],
	:nonlocalized => ['/_static/', '/_cache/']

use Utopia::Controller,
	cache_controllers: (RACK_ENV == :production)

use Utopia::Static

# Serve dynamic content
use Utopia::Content,
	cache_templates: (RACK_ENV == :production),
	tags: {
		'deferred' => Utopia::Tags::Deferred,
		'override' => Utopia::Tags::Override,
		'node' => Utopia::Tags::Node,
		'environment' => Utopia::Tags::Environment.for(RACK_ENV)
	}

run lambda { |env| [404, {}, []] }
