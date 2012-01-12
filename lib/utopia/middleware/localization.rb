#	This file is part of the "Utopia Framework" project, and is released under the MIT license.
#	Copyright 2010 Samuel Williams. All rights reserved.
#	See <utopia.rb> for licensing details.

require 'utopia/middleware'
require 'utopia/middleware/localization/name'

module Rack
	class Request
		def current_locale
			env["utopia.current_locale"]
		end
		
		def all_locales
			localization.all_locales
		end
		
		def localization
			env["utopia.localization"]
		end
	end
end

module Utopia
	module Middleware

		class Localization
			def initialize(app, options = {})
				@app = app

				@default_locale = options[:default] || "en"
				@all_locales = options[:all] || ["en"]
				
				@nonlocalized = options[:nonlocalized] || []
			end

			def named_locale(resource_name)
				if resource_name
					Name.extract_locale(resource_name, @all_locales)
				else
					nil
				end
			end

			attr :all_locales
			attr :default_locale
			
			def check_resource(resource_name, resource_locale, env)
				localized_name = Name.localized(resource_name, resource_locale, @all_locales).join(".")
				localized_path = Path.create(env["PATH_INFO"]).dirname + localized_name

				localization_probe = env.dup
				localization_probe["REQUEST_METHOD"] = "HEAD"
				localization_probe["PATH_INFO"] = localized_path.to_s

				# Find out if a resource exists for the requested localization
				return [localized_path, @app.call(localization_probe)]
			end

			def nonlocalized?(env)
				@nonlocalized.each do |pattern|
					case pattern
					when String
						return true if pattern == env["PATH_INFO"]
					when Regexp
						return true if pattern.match(env["PATH_INFO"])
					when pattern.respond_to?(:call)
						return true if pattern.call(env)
					end
				end
				
				return false
			end

			def call(env)
				# Check for a non-localized resource.
				if nonlocalized?(env)
					return @app.call(env)
				end
				
				# Otherwise, we need to check if the resource has been localized based on the request and referer parameters.
				path = Path.create(env["PATH_INFO"])
				env["utopia.localization"] = self

				referer_locale = named_locale(env['HTTP_REFERER'])
				request_locale = named_locale(path.basename)
				resource_name = Name.nonlocalized(path.basename, @all_locales).join(".")

				response = nil
				if request_locale
					env["utopia.current_locale"] = request_locale
					resource_path, response = check_resource(resource_name, request_locale, env)
				elsif referer_locale
					env["utopia.current_locale"] = referer_locale
					resource_path, response = check_resource(resource_name, referer_locale, env)
				end
				
				# If the previous checks failed, i.e. there was no request/referer locale 
				# or the response was 404 (i.e. no localised resource), we check for the
				# @default_locale
				if response == nil || response[0] >= 400
					env["utopia.current_locale"] = @default_locale
					resource_path, response = check_resource(resource_name, @default_locale, env)
				end

				# If the response is 2xx, we have a localised resource
				if response[0] < 300
					# If the original request was the same as the localized request,
					if path.basename == resource_path.basename
						# The resource URI is correct.
						return @app.call(env)
					else
						# Redirect to the correct resource URI.
						return [307, {"Location" => resource_path.to_s}, []]
					end
				elsif response[0] < 400
					# We have encountered a redirect while accessing the localized resource
					return response
				else
					# A localized resource was not found, return the unlocalised resource path,
					if path.basename == resource_name
						return @app.call(env)
					else
						return [307, {"Location" => (path.dirname + resource_name).to_s}, []]
					end
				end
			end
		end

	end
end
