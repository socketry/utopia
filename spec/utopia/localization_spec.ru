
use Utopia::Localization,
	locales: ['en', 'ja', 'de'],
	hosts: {/foobar\.com$/ => 'en', /foobar\.co\.jp$/ => 'ja', /foobar\.de$/ => 'de'}

use Utopia::Static,
	root: File.expand_path('localization_spec', __dir__)

run lambda { |env| [404, {}, []] }
