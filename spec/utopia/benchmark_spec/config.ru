#!/usr/bin/env rackup

require 'utopia'
require 'rack/cache'

use Rack::ContentLength
# use Utopia::ContentLength

class ContentLength
	STATUS_WITH_NO_ENTITY_BODY = Rack::Utils::STATUS_WITH_NO_ENTITY_BODY
	
	def initialize(app)
		@app = app
	end
	
	def length_of(body)
		if body.is_a? Array
			return body.map(&:bytesize).reduce(0, :+)
		else
			return body.bytesize
		end
	end
	
	def call(env)
		response = @app.call(env)
		
		unless response[2].empty? or response[1].include?(Rack::CONTENT_LENGTH)
			if content_length = self.content_length_of(response[2])
				response[1][Rack::CONTENT_LENGTH] = content_length
			end
		end
		
		return response
	end
end

use Utopia::Redirection::Rewrite,
	'/' => '/welcome/index'

use Utopia::Redirection::DirectoryIndex

use Utopia::Redirection::Errors,
	404 => '/errors/file-not-found'

use Utopia::Localization,
	:default_locale => 'en',
	:locales => ['en', 'de', 'ja', 'zh'],
	:nonlocalized => ['/_static/', '/_cache/']

use Utopia::Controller,
	root: File.expand_path('pages', __dir__),
	cache_controllers: true

use Utopia::Static,
	root: File.expand_path('pages', __dir__)

# Serve dynamic content
use Utopia::Content,
	root: File.expand_path('pages', __dir__),
	cache_templates: true,
	tags: {
		'deferred' => Utopia::Tags::Deferred,
		'override' => Utopia::Tags::Override,
		'node' => Utopia::Tags::Node,
	}

run lambda { |env| [404, {}, []] }
