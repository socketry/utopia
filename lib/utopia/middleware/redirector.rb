
require 'utopia/middleware'

module Utopia
	module Middleware

		class FailedRequestError < StandardError
			def initialize(resource_path, resource_status, error_path, error_status)
				@resource_path = resource_path
				@resource_status = resource_status

				@error_path = error_path
				@error_status = error_status
			end

			def to_s
				"Requested resource #{@resource_path} resulted in a #{@resource_status} error. Requested error handler #{@error_path} resulted in a #{@error_status} error."
			end
		end
		
		class ExceptionHandler
			def initialize(app, location)
				@app = app

				@location = location
			end

			def fatal_error(env, ex)
				body = StringIO.new

				body.puts "<!DOCTYPE html><html><head><title>Fatal Error</title></head><body>"

				body.puts "<h1>Fatal Error</h1>"

				body.puts "<p>While requesting resource #{env['PATH_INFO'].to_html}, a fatal error occurred.</p>"

				body.puts "<blockquote><strong>#{ex.class.name.to_html}</strong>: #{ex.to_s.to_html}</blockquote>"

				body.puts "<p>There is nothing more we can do to fix the problem at this point.</p>"

				body.puts "<p>We apologize for the inconvenience.</p>"

				body.puts "</body></html>"
				body.rewind

				return [400, {"Content-Type" => "text/html"}, body]
			end

			def redirect(env, ex)
				return @app.call(env.merge('PATH_INFO' => @location, 'REQUEST_METHOD' => 'GET'))
			end

			def call(env)
				begin
					return @app.call(env)
				rescue Exception => ex
					if env['PATH_INFO'] == @location
						return fatal_error(env, ex)
					else

						# If redirection fails
						begin
							return redirect(env, ex)
						rescue
							return fatal_error(env, ex)
						end

					end
				end
			end
		end

		# Legacy Support
		ExceptionRedirector = ExceptionHandler

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

				if @errors && response[0] >= 400 && uri = @errors[response[0]]
					error_request = env.merge("PATH_INFO" => uri, "REQUEST_METHOD" => "GET")
					error_response = @app.call(error_request)

					if error_response[0] >= 400
						raise FailedRequestError.new(env['PATH_INFO'], response[0], uri, error_response[0])
					else
						# Feed the error code back with the error document
						error_response[0] = response[0]
						return error_response
					end
				else
					return response
				end
			end
		end

	end
end
