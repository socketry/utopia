# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2016-2026, by Samuel Williams.

require "net/smtp"
require "mail"
require "console"
require "stringio"
require "yaml"

require_relative "../middleware"
require_relative "../request"
require_relative "application_errors"

module Utopia
	module Exceptions
		# A middleware which catches application exceptions and sends an email containing the exception, backtrace, request, and application state.
		class Mailer < Protocol::HTTP::Middleware
			# A basic local non-authenticated SMTP server.
			LOCAL_SMTP = [:smtp, {
				:address => "localhost",
				:port => 25,
				:enable_starttls_auto => false
			}]
			
			DEFAULT_FROM = (ENV["USER"] || "utopia").freeze
			DEFAULT_SUBJECT = "%{exception} [PID %{pid} : %{cwd}]".freeze
			ATTACHMENT_SIZE_LIMIT = 64*1024
			SENSITIVE_FIELD = /authorization|cookie|credential|password|private[_-]?key|referer|referrer|secret|session|token|variables|api[_-]?key/i
			REDACTED = "[REDACTED]".freeze
			
			# @param to [String] The address to email error reports to.
			# @param from [String] The from address for error reports.
			# @param subject [String] The subject template which can access attributes defined by `#attributes_for`.
			# @param delivery_method [Object] The delivery method as required by the mail gem.
			# @param dump_body [Boolean] Attach a bounded rewindable request body to the error report.
			# @param dump_environment [Boolean] Include application state and attach it as `state.yaml`.
			# @param attachment_size_limit [Integer] The maximum size of each attachment.
			# @param redact [Regexp | Nil] A pattern matching structured field names whose values should be redacted.
			def initialize(app, to: "postmaster", from: DEFAULT_FROM, subject: DEFAULT_SUBJECT, delivery_method: LOCAL_SMTP, dump_body: false, dump_environment: false, attachment_size_limit: ATTACHMENT_SIZE_LIMIT, redact: SENSITIVE_FIELD)
				super(app)
				
				@to = to
				@from = from
				@subject = subject
				@delivery_method = delivery_method
				@dump_body = dump_body
				@dump_environment = dump_environment
				@attachment_size_limit = Integer(attachment_size_limit)
				@redact = redact
				
				if @attachment_size_limit < 0
					raise ArgumentError, "attachment_size_limit must not be negative!"
				end
			end
			
			# Freeze this object and its internal state.
			# @returns [self] This object.
			def freeze
				return self if frozen?
				
				@to.freeze
				@from.freeze
				@subject.freeze
				@delivery_method.freeze
				@dump_body.freeze
				@dump_environment.freeze
				@attachment_size_limit.freeze
				@redact.freeze
				
				super
			end
			
			# Report application exceptions by email before returning an error response.
			# @parameter request [Utopia::Request] The request.
			# @returns [Protocol::HTTP::Response] The application response or a generated error response.
			def call(request)
				begin
					return @delegate.call(request)
				rescue *APPLICATION_ERRORS => exception
					request.exception = exception
					send_notification exception, request
					
					raise
				end
			end
			
			private
			
			REQUEST_ATTRIBUTES = [
				:method,
				:scheme,
				:authority,
				:protocol,
				:version,
				:ip,
				:referrer,
				:path,
				:request_path,
				:user_agent,
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
				
				# Do not include the raw query string, as it may contain sensitive values:
				io.puts "#{request.method} #{request.url.path.encoded}"
				
				io.puts
				
				REQUEST_ATTRIBUTES.each do |key|
					value = redact(key, request.send(key))
					io.puts "request.#{key}: #{value.inspect}"
				end
				
				request.query_parameters.each do |key, value|
					value = redact(key, value)
					io.puts "request.query_parameters.#{key}: #{value.inspect}"
				end
				
				io.puts
				
				request.headers.each do |key, value|
					value = redact(key, value)
					io.puts "header[#{key.inspect}]: #{value.inspect}"
				end
				
				if @dump_environment
					filtered_state(request).each do |key, value|
						io.puts "state.#{key}: #{value.inspect}"
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
				
				if @dump_body
					if body = extract_body(request, @attachment_size_limit)
						mail.attachments["body.bin"] = body
					end
				end
				
				if @dump_environment
					attach(mail, "state.yaml", YAML.dump(filtered_state(request)))
				end
				
				return mail
			end
			
			def send_notification(exception, request)
				mail = generate_mail(exception, request)
				
				mail.delivery_method(*@delivery_method) if @delivery_method
				
				mail.deliver
			rescue => mail_exception
				Console.warn(self, "Failed to deliver exception notification.", error: mail_exception)
			end
			
			def current_state(request)
				{
					session: request.session,
					variables: request.variables,
					localization: request.localization,
					exception: request.exception,
				}
			end
			
			def filtered_state(request)
				redact(nil, current_state(request))
			end
			
			def redact(name, value)
				if @redact && name
					if @redact.match?(name.to_s)
						return REDACTED
					end
				end
				
				case value
				when Hash
					return value.to_h do |key, item|
						[key, redact(key, item)]
					end
				when Array
					return value.map{|item| redact(nil, item)}
				else
					return value
				end
			end
			
			def attach(mail, name, content)
				if content.bytesize <= @attachment_size_limit
					mail.attachments[name] = content
				end
			end
			
			def extract_body(request, size_limit)
				body = request.body
				
				if body&.rewindable? && body.rewind
					buffer = String.new.b
					
					body.each do |chunk|
						# Do not retain a partial body when the complete attachment would exceed the limit:
						if chunk.bytesize > size_limit - buffer.bytesize
							return nil
						end
						
						buffer << chunk
					end
					
					return buffer unless buffer.empty?
				end
			end
		end
	end
end
