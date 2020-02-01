#!/usr/bin/env rackup
# frozen_string_literal: true

require 'utopia'
require 'json'

require 'rack/freeze'

use Utopia::ContentLength

use Utopia::Redirection::Rewrite,
	'/' => '/welcome/index'

use Utopia::Redirection::DirectoryIndex

use Utopia::Redirection::Errors,
	404 => '/errors/file-not-found'

# use Utopia::Localization,
# 	:default_locale => 'en',
# 	:locales => ['en', 'de', 'ja', 'zh']

use Utopia::Controller,
	root: File.expand_path('pages', __dir__)

use Utopia::Static,
	root: File.expand_path('pages', __dir__)

# Serve dynamic content
use Utopia::Content,
	root: File.expand_path('pages', __dir__)

run lambda { |env| [404, {}, []] }
