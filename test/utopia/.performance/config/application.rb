# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2016-2026, by Samuel Williams.

require "json"

require "utopia/application"
require "utopia/controller"
require "utopia/content"
require "utopia/redirection"
require "utopia/static"

ROOT = File.expand_path("../pages", __dir__)

Application = Utopia::Application.build do
	use Utopia::Redirection::Rewrite, {
		"/" => "/welcome/index"
	}
	
	use Utopia::Redirection::DirectoryIndex
	
	use Utopia::Redirection::Errors, {
		404 => "/errors/file-not-found"
	}
	
	use Utopia::Controller, root: ROOT
	use Utopia::Static, root: ROOT
	use Utopia::Content, root: ROOT
end
