
use Utopia::Localization,
	locales: ['en', 'ja', 'de'],
	hosts: {/foobar\.com$/ => 'en', /foobar\.co\.jp$/ => 'ja', /foobar\.de$/ => 'de'}

use Utopia::Static,
	root: File.expand_path('../pages', __FILE__)

use Utopia::Content,
	root: File.expand_path('../pages', __FILE__)

run lambda { |env| [404, {}, []] }
