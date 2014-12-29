
use Utopia::Middleware::Localization,
	locales: ['en', 'jp', 'de']

use Utopia::Middleware::Static,
	root: File.expand_path('../pages', __FILE__)

use Utopia::Middleware::Content,
	root: File.expand_path('../pages', __FILE__)

run lambda { |env| [404, {}, []] }
