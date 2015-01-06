#!/usr/bin/env rackup

UTOPIA_ENV = (ENV['UTOPIA_ENV'] || ENV['RACK_ENV'] || :development).to_sym
$LOAD_PATH << File.join(File.dirname(__FILE__), "lib")

require 'utopia'

# Utopia relies heavily on a local cache:
require 'rack/cache'

if UTOPIA_ENV == :development
	use Rack::ShowExceptions
else
	use Utopia::Middleware::ExceptionHandler, "/errors/exception"
	use Utopia::Middleware::MailExceptions
end

use Rack::ContentLength

use Utopia::Middleware::Redirector, {
	:strings => {
		'/' => '/welcome/index',
	},
	:errors => {
		404 => "/errors/file-not-found"
	}
}

use Utopia::Middleware::DirectoryIndex

use Utopia::Middleware::Controller,
	cache_controllers: (UTOPIA_ENV == :production)

# To enable full Sendfile support, please refer to the Rack::Sendfile documentation for your webserver.
use Rack::Sendfile
use Utopia::Middleware::Static

if UTOPIA_ENV == :production
	use Rack::Cache, {
		:metastore => "file:#{Utopia::Middleware::default_root("cache/meta")}",
		:entitystore => "file:#{Utopia::Middleware::default_root("cache/body")}",
		:verbose => false
	}
end

use Utopia::Middleware::Content,
	cache_templates: (UTOPIA_ENV == :production)

run lambda { |env| [404, {}, []] }
