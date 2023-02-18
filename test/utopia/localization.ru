# frozen_string_literal: true

localization_spec_root = File.expand_path('.localization', __dir__)

use Utopia::Localization,
	locales: ['en', 'ja', 'de'],
	hosts: {/foobar\.com$/ => 'en', /foobar\.co\.jp$/ => 'ja', /foobar\.de$/ => 'de'}

use Utopia::Controller,
	root: localization_spec_root

use Utopia::Static,
	root: localization_spec_root

run lambda { |env| [404, {}, []] }
