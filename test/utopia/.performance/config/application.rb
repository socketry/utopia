# frozen_string_literal: true

require "json"

require "utopia/application"
require "utopia/controller"
require "utopia/content"
require "utopia/redirection"
require "utopia/static"

ROOT = File.expand_path("../pages", __dir__)

Application = Utopia::Application.build do
	use Utopia::Redirection do |redirects|
		redirects.rewrite "/" => "/welcome/index"
		redirects.directory_index
		redirects.error 404, "/errors/file-not-found"
	end
	
	use Utopia::Controller, root: ROOT
	use Utopia::Static, root: ROOT
	use Utopia::Content, root: ROOT
end
