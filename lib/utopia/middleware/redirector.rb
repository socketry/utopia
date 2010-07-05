#	This file is part of the "Utopia Framework" project, and is licensed under the GNU AGPLv3.
#	Copyright 2010 Samuel Williams. All rights reserved.
#	See <utopia.rb> for licensing details.

require 'utopia/middleware'
require 'utopia/extensions/regexp'
require 'utopia/extensions/string'

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
					log = Logger.new(env['rack.errors'])
					
					log.error "Exception #{ex.to_s.dump}!"
					
					ex.backtrace.each do |bt|
						log.error bt
					end
					
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
			def normalize_strings(strings)
				normalized = {}
				
				strings.each_pair do |key, value|
					if Array === key
						key.each { |s| normalized[s] = value }
					else
						normalized[key] = value
					end
				end
				
				return normalized
			end

			def normalize_patterns(patterns)
				normalized = []
				
				patterns.each do |pattern|
					uri = pattern.pop
					
					pattern.each do |key|
						normalized.push([key, uri])
					end
				end
				
				return normalized
			end

			public
			def initialize(app, options = {})
				@app = app

				@strings = options[:strings] || {}
				@patterns = options[:patterns] || {}

				@strings = normalize_strings(@strings)
				@patterns = normalize_patterns(@patterns)

				@errors = options[:errors]

				LOG.info "** #{self.class.name}: Running with #{@strings.size + @patterns.size} rules"
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
					if match_data = pattern.match(base_path)
						result = redirect(uri, match_data)

						return result if result != nil
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
