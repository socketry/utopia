# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2016-2025, by Samuel Williams.

require "net/smtp"
require "mail"

require_relative "../middleware"

module Utopia
	module Exceptions
		# A middleware which catches all exceptions raised from the app it wraps and sends a useful email with the exception, stacktrace, and contents of the environment.
		class Mailer
			# A basic local non-authenticated SMTP server.
			LOCAL_SMTP = [:smtp, {
				:address => "localhost",
				:port => 25,
				:enable_starttls_auto => false
			}]
			
			DEFAULT_FROM = (ENV["USER"] || "utopia").freeze
			DEFAULT_SUBJECT = "%{exception} [PID %{pid} : %{cwd}]".freeze
			
			# @param to [String] The address to email error reports to.
			# @param from [String] The from address for error reports.
			# @param subject [String] The subject template which can access attributes defined by `#attributes_for`.
			# @param delivery_method [Object] The delivery method as required by the mail gem.
			# @param dump_environment [Boolean] Attach request attributes as `attributes.yaml` to the error report.
			def initialize(app, to: "postmaster", from: DEFAULT_FROM, subject: DEFAULT_SUBJECT, delivery_method: LOCAL_SMTP, dump_environment: false)
				@app = app
				
				@to = to
				@from = from
				@subject = subject
				@delivery_method = delivery_method
				@dump_environment = dump_environment
			end
			
			def freeze
				return self if frozen?
				
				@to.freeze
				@from.freeze
				@subject.freeze
				@delivery_method.freeze
				@dump_environment.freeze
				
				super
			end
			
			def call(request)
				begin
					return @app.call(request)
				rescue => exception
					send_notification exception, request
					
					raise
				end
			end
			
			private
			
			REQUEST_KEYS = [
				:ip,
				:referrer,
				:path,
				:user_agent,
			]
			
			ENV_KEYS = [
				"PATH_INFO",
				"REQUEST_METHOD",
				"REQUEST_PATH",
				"REQUEST_URI",
				"SCRIPT_NAME",
				"QUERY_STRING",
				"SERVER_PROTOCOL",
				"SERVER_NAME",
				"SERVER_PORT",
				"REMOTE_ADDR",
				"CONTENT_TYPE",
				"CONTENT_LENGTH",
			]
			
			def generate_backtrace(io, exception, prefix: "Exception")
				io.puts "#{prefix} #{exception.class.name}: #{exception.to_s}"
				
				if exception.respond_to?(:backtrace)
					io.puts exception.backtrace
				else
					io.puts exception.to_s
				end
				
				if cause = exception.cause
					generate_backtrace(io, cause, prefix: "Caused by")
				end
			end
			
			def generate_body(exception, request)
				io = StringIO.new
				
				io.puts "#{request.method} #{request.url}"
				
				# TODO embed the request body if it's textual?
				# TODO dump and embed `utopia.variables`?
				
				io.puts
				
				REQUEST_KEYS.each do |key|
					value = request.send(key)
					io.puts "request.#{key}: #{value.inspect}"
				end
				
				request.arguments.each do |key, value|
					io.puts "request.arguments.#{key}: #{value.inspect}"
				end
				
				io.puts
				
				ENV_KEYS.each do |key|
					value = request[key]
					io.puts "request[#{key.inspect}]: #{value.inspect}"
				end
				
				io.puts
				
				request.headers.each do |key, value|
					io.puts "header[#{key.inspect}]: #{value.inspect}"
				end
				
				request.attributes.each do |key, value|
					if key.is_a?(String) && key.start_with?("HTTP_")
						io.puts "#{key}: #{value.inspect}"
					end
				end
				
				io.puts
				
				generate_backtrace(io, exception)
				
				return io.string
			end
			
			def attributes_for(exception, request)
				{
					exception: exception.class.name,
					pid: $$,
					cwd: Dir.getwd,
				}
			end
			
			def generate_mail(exception, request)
				mail = Mail.new(
					:from => @from,
					:to => @to,
					:subject => @subject % attributes_for(exception, request)
				)
				
				mail.text_part = Mail::Part.new
				mail.text_part.body = generate_body(exception, request)
				
				if body = extract_body(request) and body.size > 0
					mail.attachments["body.bin"] = body
				end
				
				if @dump_environment
					mail.attachments["attributes.yaml"] = YAML.dump(request.attributes)
				end
				
				return mail
			end
			
			def send_notification(exception, request)
				mail = generate_mail(exception, request)
				
				mail.delivery_method(*@delivery_method) if @delivery_method
				
				mail.deliver
			rescue => mail_exception
				$stderr.puts mail_exception.to_s
				$stderr.puts mail_exception.backtrace
			end
			
			def extract_body(request)
				request.body&.read
			end
		end
	end
end
