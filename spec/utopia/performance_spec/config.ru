#!/usr/bin/env rackup

require 'utopia'
require 'json'

# use Rack::ContentLength
use Utopia::ContentLength

use Utopia::Redirection::Rewrite,
	'/' => '/welcome/index'

use Utopia::Redirection::DirectoryIndex

use Utopia::Redirection::Errors,
	404 => '/errors/file-not-found'

# use Utopia::Localization,
# 	:default_locale => 'en',
# 	:locales => ['en', 'de', 'ja', 'zh'],
# 	:ignore => ['/_static/', '/_cache/']

use Utopia::Controller,
	root: File.expand_path('pages', __dir__),
	base: Utopia::Controller::Base,
	cache_controllers: true

use Utopia::Static,
	root: File.expand_path('pages', __dir__)

# Serve dynamic content
use Utopia::Content,
	root: File.expand_path('pages', __dir__),
	cache_templates: true

run lambda { |env| [404, {}, []] }
