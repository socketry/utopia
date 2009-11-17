# cacheing middleware

require 'utopia/middleware'
require 'utopia/response_helper'
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
			end

			def named_locale(resource_name)
				Name.extract_locale(resource_name, @all_locales)
			end
			
			def current_locale(env, resource_name)
				Rack::Request.new(env).GET["locale"] || named_locale(resource_name) || @default_locale
			end

			attr :all_locales
			attr :default_locale

			def call(env)
				path = Path.create(env["PATH_INFO"])

				request_locale = current_locale(env, path.basename)
				resource_name = Name.nonlocalized(path.basename, @all_locales).join(".")

				env["utopia.current_locale"] = request_locale
				env["utopia.localization"] = self

				localized_name = Name.localized(resource_name, request_locale, @all_locales).join(".")

				localization_probe = env.dup
				localization_probe["REQUEST_METHOD"] = "HEAD"
				localization_probe["PATH_INFO"] = (path.dirname + localized_name).to_s

				response = @app.call(localization_probe)

				if response[0] < 300
					if path.basename == localized_name
						return @app.call(env)
					else
						return [307, {"Location" => localization_probe["PATH_INFO"]}, []]
					end
				elsif response[0] < 400
					return response
				else
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
