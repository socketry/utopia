
require 'utopia/middleware'

module Utopia
	module Middleware

		class ExceptionRedirector
			def initialize(app, location)
				@app = app
				
				@location = location
			end
			
			def call(env)
				begin
					return @app.call(env)
				rescue
					return [301, {"Location" => @location}, []]
				end
			end
		end

		class Redirector
			private
			def normalize_keys(redirects)
				redirects.each do |key, value|
					result = nil

					case value
					when String
						result = @strings
					when Regexp
						result = @patterns
					else
						$stderr.puts "Warning, could not process redirect #{key.inspect} to #{value.inspect}!"
						next
					end

					if key.kind_of? Array
						key.each do |subkey|
							result[subkey]  = value
						end
					else
						result[key] = value
					end
				end
			end

			public
			def initialize(app, options = {})
				@app = app

				@strings = {}
				@patterns = {}

				normalize_keys(options[:redirects]) if options[:redirects]

				@errors = options[:errors]

				LOG.info "#{self.class.name}: Running with #{@strings.size + @patterns.size} rules"
			end

			def redirect(uri, match_data)
				if uri.respond_to? :call
					return uri.call(match_data)
				else
					return [301, {"Location" => uri.to_s}, []]
				end
			end

			def call(env)
				base_path = env['PATH_INFO']

				if uri = @strings[base_path]
					return redirect(@strings[base_path], base_path)
				end

				@patterns.each do |pattern, uri|
					if match_data = base_path.match(pattern)
						return redirect(uri, match_data)
					end
				end

				response = @app.call(env)

				if response[0] >= 400 && uri = @errors[response[0]]
					return redirect(uri, base_path)
				else
					return response
				end
			end
		end

	end
end
