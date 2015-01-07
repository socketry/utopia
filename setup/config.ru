#!/usr/bin/env rackup

# Setup the server environment:
RACK_ENV = ENV.fetch('RACK_ENV', :development).to_sym unless defined?(RACK_ENV)

# Allow loading library code from lib directory:
$LOAD_PATH << File.expand_path("../lib", __FILE__)

require 'utopia'
require 'rack/cache'

if RACK_ENV == :production
	use Utopia::ExceptionHandler, "/errors/exception"
	use Utopia::MailExceptions
else
	use Rack::ShowExceptions
end

use Rack::ContentLength

use Utopia::Redirector,
	strings: {
		'/' => '/welcome/index',
	},
	errors: {
		404 => "/errors/file-not-found"
	}

use Utopia::DirectoryIndex

use Utopia::Controller,
	cache_controllers: (RACK_ENV == :production)

# To enable full Sendfile support, please refer to the Rack::Sendfile documentation for your webserver.
use Rack::Sendfile
use Utopia::Static

if RACK_ENV == :production
	use Rack::Cache,
		metastore: "file:#{Utopia::default_root("cache/meta")}",
		entitystore: "file:#{Utopia::default_root("cache/body")}",
		verbose: false
end

use Utopia::Content,
	cache_templates: (RACK_ENV == :production),
	tags: {
		'deferred': Utopia::Tags::Deferred,
		'environment': Utopia::Tags::Environment.for(RACK_ENV)
	}

run lambda { |env| [404, {}, []] }
