# Copyright, 2012, by Samuel G. D. Williams. <http://www.codeotaku.com>
# 
# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:
# 
# The above copyright notice and this permission notice shall be included in
# all copies or substantial portions of the Software.
# 
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
# THE SOFTWARE.

require_relative 'middleware'

module Utopia
	# A middleware which attempts to find localized content.
	class Localization
		# A wrapper to provide easy access to locale related data in the request.
		class Wrapper
			def initialize(env)
				@env = env
			end
			
			def localization
				@env[LOCALIZATION_KEY]
			end
			
			# Returns the current locale or nil if not localized.
			def current_locale
				@env[CURRENT_LOCALE_KEY]
			end
			
			# Returns the default locale or nil if not localized.
			def default_locale
				localization && localization.default_locale
			end
			
			# Returns an empty array if not localized.
			def all_locales
				localization && localization.all_locales || []
			end
		end
		
		def self.[] request
			Wrapper.new(request.env)
		end
		
		RESOURCE_NOT_FOUND = [400, {}, []].freeze
		
		HTTP_ACCEPT_LANGUAGE = 'HTTP_ACCEPT_LANGUAGE'.freeze
		LOCALIZATION_KEY = 'utopia.localization'.freeze
		CURRENT_LOCALE_KEY = 'utopia.localization.current_locale'.freeze
		
		# @param locales [Array<String>] An array of all supported locales.
		# @param default_locale [String] The default locale if none is provided.
		# @param default_locales [String] The locales to try in order if none is provided.
		# @param hosts [Hash<Pattern, String>] Specify a mapping of the HTTP_HOST header to a given locale.
		# @param ignore [Array<Pattern>] A list of patterns matched against PATH_INFO which will not be localized.
		def initialize(app, locales:, default_locale: nil, default_locales: nil, hosts: {}, ignore: [], **options)
			@app = app
			
			@all_locales = HTTP::Accept::Languages::Locales.new(locales)
			
			# Locales here are represented as an array of strings, e.g. ['en', 'ja', 'cn', 'de'] and are used in order if no locale is specified by the user.
			unless @default_locales = default_locales
				# We append nil, i.e. no localization.
				@default_locales = @all_locales.names + [nil]
			end
			
			@default_locale = default_locale || @default_locales.first
			
			unless @default_locales.include? @default_locale
				@default_locales.unshift(@default_locale)
			end
			
			# Select a localization based on a request host name:
			@hosts = hosts
			
			@ignore = ignore || options[:nonlocalized]
		end
		
		def freeze
			@app.freeze
			
			@all_locales.freeze
			@default_locales.freeze
			@default_locale.freeze
			@hosts.freeze
			@ignore.freeze
			
			super
		end
		
		attr :all_locales
		attr :default_locale
		
		def preferred_locales(env)
			return to_enum(:preferred_locales, env) unless block_given?
			
			# Keep track of what locales have been tried:
			locales = Set.new
			
			host_preferred_locales(env) do |locale|
				yield env.merge(CURRENT_LOCALE_KEY => locale) if locales.add? locale
			end
			
			request_preferred_locale(env) do |locale, path|
				# We have extracted a locale from the path, so from this point on we should use the updated path:
				env = env.merge(Rack::PATH_INFO => path.to_s)
				
				yield env.merge(CURRENT_LOCALE_KEY => locale) if locales.add? locale
			end
			
			browser_preferred_locales(env).each do |locale|
				yield env.merge(CURRENT_LOCALE_KEY => locale) if locales.add? locale
			end
			
			@default_locales.each do |locale|
				yield env.merge(CURRENT_LOCALE_KEY => locale) if locales.add? locale
			end
		end
		
		def host_preferred_locales(env)
			http_host = env[Rack::HTTP_HOST]
			
			# Yield all hosts which match the incoming http_host:
			@hosts.each do |pattern, locale|
				yield locale if http_host[pattern]
			end
		end
		
		def request_preferred_locale(env)
			path = Path[env[Rack::PATH_INFO]]
			
			if request_locale = @all_locales.patterns[path.first]
				# Remove the localization prefix:
				path.delete_at(0)
				
				yield request_locale, path
			end
		end
		
		def browser_preferred_locales(env)
			accept_languages = env[HTTP_ACCEPT_LANGUAGE]
			
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
		
		SAFE_METHODS = ['GET', 'HEAD']
		
		def localized?(env)
			# Only SAFE_METHODS can be localized:
			request_method = env[Rack::REQUEST_METHOD]
			return false unless SAFE_METHODS.include?(request_method)
			
			# Ignore requests which match the ignored paths:
			path_info = env[Rack::PATH_INFO]
			return false if @ignore.any? { |pattern| path_info[pattern] != nil }
			
			return true
		end
		
		# Set the Vary: header on the response to indicate that this response should include the header in the cache key.
		def vary(env, response)
			headers = response[1]
			
			# This response was based on the Accept-Language header:
			if headers['Vary']
				headers['Vary'] += ',Accept-Language'
			else
				headers['Vary'] = 'Accept-Language'
			end
			
			# Althought this header is generally not supported, we supply it anyway as it is useful for debugging:
			if locale = env[CURRENT_LOCALE_KEY]
				# Set the Content-Location to point to the localized URI as requested:
				headers['Content-Location'] = "/#{locale}" + env[Rack::PATH_INFO]
			end
			
			return response
		end
		
		def call(env)
			# Pass the request through if it shouldn't be localized:
			return @app.call(env) unless localized?(env)
			
			env[LOCALIZATION_KEY] = self
			
			response = nil
			
			# We have a non-localized request, but there might be a localized resource. We return the best localization possible:
			preferred_locales(env) do |localized_env|
				# puts "Trying locale: #{env[CURRENT_LOCALE_KEY]}: #{env[Rack::PATH_INFO]}..."
				
				response = @app.call(localized_env)
				
				break unless response[0] >= 400
			end
			
			return vary(env, response)
		end
	end
end
