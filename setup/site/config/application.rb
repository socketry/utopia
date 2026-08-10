# frozen_string_literal: true

require_relative "environment"

require "utopia/application"
require "utopia/controller"
require "utopia/content"
require "utopia/exceptions"
require "utopia/localization"
require "utopia/redirection"
require "utopia/session"
require "utopia/static"

Application = Utopia::Application.build do
	if UTOPIA.production?
		# Handle exceptions in production with an error page and send an email notification:
		use Utopia::Exceptions::Handler
		use Utopia::Exceptions::Mailer
	end
	
	use Utopia::Localization,
		default_locale: "en",
		locales: ["en", "de", "ja", "zh"]
	
	# Serve static files from "public" directory:
	use Utopia::Static, root: "public"
	
	use Utopia::Redirection do |redirects|
		redirects.rewrite "/" => "/welcome/index"
		redirects.directory_index
		redirects.error 404, "/errors/file-not-found"
	end
	
	use Utopia::Session,
		expires_after: 3600 * 24,
		secret: UTOPIA.secret_for(:session),
		secure: true
	
	use Utopia::Controller
	
	# Serve static files from "pages" directory:
	use Utopia::Static
	
	# Serve dynamic content:
	use Utopia::Content
end
