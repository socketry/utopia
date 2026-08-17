# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2026, by Samuel Williams.

require_relative "../../../../utopia/static/middleware"

require "traces/provider"

Traces::Provider(Utopia::Static::Middleware) do
	def respond(request, path, extension, content_type, localization: request.localization)
		attributes = {
			path: path,
			locale: localization&.locale,
		}
		
		Traces.trace("utopia.static.respond", attributes: attributes){super}
	end
end
