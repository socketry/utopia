# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2025-2026, by Samuel Williams.

require_relative "wrapper"
require_relative "../context"
require_relative "../middleware"
require_relative "../response"

module Utopia
	module Localization
		class Middleware
			RESOURCE_NOT_FOUND = Response[400, {}, []].freeze
			
			HTTP_ACCEPT_LANGUAGE = "HTTP_ACCEPT_LANGUAGE".freeze
			
			# @param locales [Array<String>] An array of all supported locales.
			# @param default_locale [String] The default locale if none is provided.
			# @param default_locales [String] The locales to try in order if none is provided.
			# @param hosts [Hash<Pattern, String>] Specify a mapping of the HTTP_HOST header to a given locale.
			# @param ignore [Array<Pattern>] A list of patterns matched against PATH_INFO which will not be localized.
			def initialize(app, locales:, default_locale: nil, default_locales: nil, hosts: {}, ignore: [])
				@app = app
				
				@all_locales = HTTP::Accept::Languages::Locales.new(locales)
				
				# Locales here are represented as an array of strings, e.g. ['en', 'ja', 'cn', 'de'] and are used in order if no locale is specified by the user.
				unless @default_locales = default_locales
					if default_locale
						@default_locales = [default_locale, nil]
					else
						# We append nil, i.e. no localization.
						@default_locales = @all_locales.names + [nil]
					end
				end
				
				@default_locale = default_locale || @default_locales.first
				
				unless @default_locales.include? @default_locale
					@default_locales.unshift(@default_locale)
				end
				
				# Select a localization based on a request host name:
				@hosts = hosts
				
				@ignore = ignore || options[:nonlocalized]
				
				@methods = methods
			end
			
			def freeze
				return self if frozen?
				
				@all_locales.freeze
				@default_locales.freeze
				@default_locale.freeze
				@hosts.freeze
				@ignore.freeze
				
				super
			end
			
			attr :all_locales
			attr :default_locale
			
			def preferred_locales(request)
				return to_enum(:preferred_locales, request) unless block_given?
				
				# Keep track of what locales have been tried:
				locales = Set.new
				
				host_preferred_locales(request) do |locale|
					yield request, locale if locales.add? locale
				end
				
				request_preferred_locale(request) do |locale, path|
					# We have extracted a locale from the path, so from this point on we should use the updated path:
					request = request.with(path_info: path.to_s)
					
					yield request, locale if locales.add? locale
				end
				
				browser_preferred_locales(request).each do |locale|
					yield request, locale if locales.add? locale
				end
				
				@default_locales.each do |locale|
					yield request, locale if locales.add? locale
				end
			end
			
			def host_preferred_locales(request)
				http_host = request.host.to_s
				
				# Yield all hosts which match the incoming http_host:
				@hosts.each do |pattern, locale|
					yield locale if http_host[pattern]
				end
			end
			
			def request_preferred_locale(request)
				path = Path[request.path_info]
				
				if request_locale = @all_locales.patterns[path.first]
					# Remove the localization prefix:
					path.delete_at(0)
					
					yield request_locale, path
				end
			end
			
			def browser_preferred_locales(request)
				accept_languages = request.headers["accept-language"]&.to_s
				
				# No user prefered languages:
				return [] unless accept_languages
				
				# Extract the ordered list of languages:
				languages = HTTP::Accept::Languages.parse(accept_languages)
				
				# Returns available languages based on the order languages:
				return @all_locales & languages
			rescue HTTP::Accept::ParseError
				# If we fail to parse the browser Accept-Language header, we ignore it (silently).
				return []
			end
			
			def localized?(request)
				# Ignore requests which match the ignored paths:
				path_info = request.path_info
				return false if @ignore.any?{|pattern| path_info[pattern] != nil}
				
				return true
			end
			
			# Set the Vary: header on the response to indicate that this response should include the header in the cache key.
			def vary(request, response)
				response = Response.wrap(response)
				headers = response.headers
				
				# This response was based on the Accept-Language header:
				headers.add("vary", "Accept-Language")
				
				# Althought this header is generally not supported, we supply it anyway as it is useful for debugging:
				if locale = Context.current_locale
					# Set the Content-Location to point to the localized URI as requested:
					headers["content-location"] = "/#{locale}" + request.path_info
				end
				
				return response
			end
			
			def call(request)
				# Pass the request through if it shouldn't be localized:
				return @app.call(request) unless localized?(request)
				
				response = nil
				
				# We have a non-localized request, but there might be a localized resource. We return the best localization possible:
				preferred_locales(request) do |localized_request, locale|
					# puts "Trying locale: #{locale}: #{localized_request.path_info}..."
					
					response = Context.with(request: localized_request, localization: self, current_locale: locale) do
						Response.wrap(@app.call(localized_request))
					end
					
					break unless response.status >= 400
					
					response.close if response.respond_to?(:close)
				end
				
				return vary(request, response)
			end
		end
	end
end
