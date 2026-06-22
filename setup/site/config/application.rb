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
	
	# Serve static files from "public" directory:
	use Utopia::Static, root: "public"
	
	use Utopia::Redirection::Rewrite, {
		"/" => "/welcome/index"
	}
	
	use Utopia::Redirection::DirectoryIndex
	
	use Utopia::Redirection::Errors, {
		404 => "/errors/file-not-found"
	}
	
	use Utopia::Localization,
		default_locale: "en",
		locales: ["en", "de", "ja", "zh"]
	
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
