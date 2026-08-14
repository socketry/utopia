# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2026, by Samuel Williams.

require_relative "../response"

module Utopia
	module Localization
		# Resolves localized resources from immutable request preferences.
		module Resolver
			CONTENT_LANGUAGE = "content-language".freeze
			CONTENT_LOCATION = "content-location".freeze
			
		private
			
			# Resolve a response by trying each preferred locale in order.
			def resolve_localized(request)
				if localization = request.localization
					localization.preferred_locales.each do |locale|
						selected = localization.with(locale: locale)
						
						if response = yield(selected)
							return localized_response(request, response, selected)
						end
					end
				else
					return yield(nil)
				end
				
				return nil
			end
			
			# Describe the selected localized representation in its response metadata.
			def localized_response(request, response, localization)
				response = Response.wrap(response)
				
				if locale = localization.locale
					response.headers[CONTENT_LANGUAGE] = locale
					response.headers[CONTENT_LOCATION] = localization.localized_path(request.url.path.encoded)
				end
				
				return response
			end
		end
	end
end
