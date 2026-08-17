# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2026, by Samuel Williams.

require_relative "../../../../utopia/content/middleware"

require "traces/provider"

Traces::Provider(Utopia::Content::Middleware) do
	def respond(link, request, localization: request.localization)
		attributes = {
			"link.key" => link.key,
			"link.href" => link.href,
			"link.locale" => localization&.locale,
		}
		
		Traces.trace("utopia.content.middleware.respond", attributes: attributes){super}
	end
end
