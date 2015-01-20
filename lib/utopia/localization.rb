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

module Rack
	class Request
		def current_locale
			env[Utopia::Localization::CURRENT_LOCALE_KEY]
		end
		
		def all_locales
			localization.all_locales
		end
		
		def localization
			env[Utopia::Localization::LOCALIZATION_KEY]
		end
	end
end

module Utopia
	class Localization
		RESOURCE_NOT_FOUND = [400, {}, []].freeze
		
		HTTP_ACCEPT_LANGUAGE = 'HTTP_ACCEPT_LANGUAGE'.freeze
		LOCALIZATION_KEY = 'utopia.localization'.freeze
		CURRENT_LOCALE_KEY = 'utopia.localization.current_locale'.freeze
		
		def initialize(app, options = {})
			@app = app

			@default_locale = options[:default_locale] || "en"
			@all_locales = options[:locales] || ["en"]
		end

		attr :all_locales
		attr :default_locale

		def preferred_locales(env)
			locales = browser_preferred_locales(env)
			locales << @default_locale unless locales.include? @default_locale
			
			return locales
		end
		
		def browser_preferred_locales(env)
			accept_languages = env[HTTP_ACCEPT_LANGUAGE]
			
			# No user prefered languages:
			return [] unless accept_languages

			languages = accept_languages.split(',').map { |language|
				language.split(';q=').tap{|x| x[1] = (x[1] || 1.0).to_f}
			}.sort{|a, b| b[1] <=> a[1]}.collect(&:first)
			
			# Returns languages based on the order of the first argument
			return languages & @all_locales
		end

		def call(env)
			env[LOCALIZATION_KEY] = self
			path = Path[env['PATH_INFO']]
			
			# Are we already within a localized hierarchy?
			if all_locales.include? path.first
				# This is a localized path with a specific localization, e.g. '/fr/test.txt' so we should rewrite the request to the non-localized path but specify the localized header:
				env[CURRENT_LOCALE_KEY] = path.first
				
				# Remove the localization prefix.
				path.delete_at(0)
				env["PATH_INFO"] = path.to_s
			else
				# We have a non-localized request, but there might be a localized resource. We return the best localization possible:
				preferred_locales(env).each do |locale|
					env[CURRENT_LOCALE_KEY] = locale
					
					response = @app.call(env)
					
					# Response can be considered successful:
					return response unless response[0] >= 400
				end
				
				# No locale specific resource was found:
				env.delete(CURRENT_LOCALE_KEY)
			end
			
			return @app.call(env)
		end
	end
end
