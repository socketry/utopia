# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2025-2026, by Samuel Williams.

require_relative "preferences"
require_relative "../middleware"
require_relative "../request"
require_relative "../response"

require "set"

module Utopia
	module Localization
		# Computes localization preferences and rewrites locale-prefixed paths.
		class Middleware < Protocol::HTTP::Middleware
			# @param locales [Array<String>] An array of all supported locales.
			# @param default_locale [String] The default locale if none is provided.
			# @param default_locales [Array<String | Nil>] The locales to try in order if none is provided.
			# @param hosts [Hash<Pattern, String>] Specify a mapping of request hosts to locales.
			# @param ignore [Array<Pattern>] A list of patterns matched against request paths which will not be localized.
			def initialize(app, locales:, default_locale: nil, default_locales: nil, hosts: {}, ignore: [])
				super(app)
				
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
				
				@ignore = ignore
			end
			
			# Freeze this object and its internal state.
			# @returns [self] This object.
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
			
			# Compute the preferred locales for a request.
			# @parameter request [Utopia::Request] The application request.
			# @parameter path_locale [String | Nil] The locale extracted from the request path.
			# @returns [Array(String | Nil)] The unique locales in preference order.
			def preferred_locales(request, path_locale = nil)
				# Keep track of what locales have been tried:
				locales = Set.new
				
				if path_locale
					locales.add(path_locale)
				end
				
				host_preferred_locales(request) do |locale|
					locales.add(locale)
				end
				
				browser_preferred_locales(request).each do |locale|
					locales.add(locale)
				end
				
				@default_locales.each do |locale|
					locales.add(locale)
				end
				
				return locales.to_a
			end
			
			# Infer preferred locales from the request host.
			# @parameter request [Utopia::Request] The application request.
			# @yields {|locale| ...} Each locale whose host pattern matches the request host.
			# @returns [Hash] The configured host mappings.
			def host_preferred_locales(request)
				http_host = request.host.to_s
				
				# Yield all hosts which match the incoming http_host:
				@hosts.each do |pattern, locale|
					if http_host[pattern]
						yield locale
					end
				end
			end
			
			# Extract a locale prefix from the request path.
			# @parameter request [Utopia::Request] The application request.
			# @returns [Array(Utopia::Request, String | Nil)] The request and extracted locale.
			def extract_path_locale(request)
				path = Path[request.path_info]
				
				if request_locale = @all_locales.patterns[path.first]
					# Remove the localization prefix:
					path.delete_at(0)
					
					return request.with(path_info: path.to_s), request_locale
				else
					return request, nil
				end
			end
			
			# Parse the locales preferred by the browser.
			# @parameter request [Utopia::Request] The application request.
			# @returns [Array(String)] Supported locales accepted by the browser, in preference order.
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
			
			# Check whether the request path includes a locale.
			# @parameter request [Utopia::Request] The application request.
			# @returns [Boolean] Whether the path is eligible for localization.
			def localized?(request)
				# Ignore requests which match the ignored paths:
				path_info = request.path_info
				return false if @ignore.any?{|pattern| path_info[pattern] != nil}
				
				return true
			end
			
			# Mark the response as varying by language.
			# @parameter response [Protocol::HTTP::Response] The response.
			# @returns [Protocol::HTTP::Response] The response with localization headers.
			def vary(response)
				response = Response.wrap(response)
				headers = response.headers
				
				# This response was based on the Accept-Language header:
				headers.add("vary", "Accept-Language")
				
				return response
			end
			
			# Attach localization preferences and invoke the application once.
			# @parameter request [Utopia::Request] The request.
			# @returns [Protocol::HTTP::Response] The response with cache-variation headers.
			def call(request)
				# Pass the request through if it shouldn't be localized:
				return @delegate.call(request) unless localized?(request)
				
				request, path_locale = extract_path_locale(request)
				locales = preferred_locales(request, path_locale)
				
				request.localization = Preferences.new(
					all_locales: @all_locales.names,
					preferred_locales: locales,
					default_locale: @default_locale,
				)
				
				return vary(@delegate.call(request))
			end
		end
	end
end
