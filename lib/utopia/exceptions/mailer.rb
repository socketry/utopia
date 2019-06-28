# Copyright, 2016, by Samuel G. D. Williams. <http://www.codeotaku.com>
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

require 'net/smtp'
require 'mail'

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
			
			DEFAULT_FROM = (ENV['USER'] || 'utopia').freeze
			DEFAULT_SUBJECT = '%{exception} [PID %{pid} : %{cwd}]'.freeze
			
			# @param to [String] The address to email error reports to.
			# @param from [String] The from address for error reports.
			# @param subject [String] The subject template which can access attributes defined by `#attributes_for`.
			# @param delivery_method [Object] The delivery method as required by the mail gem.
			# @param dump_environment [Boolean] Attach `env` as `environment.yaml` to the error report.
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
			
			def call(env)
				begin
					return @app.call(env)
				rescue => exception
					send_notification exception, env
					
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
			
			def generate_body(exception, env)
				io = StringIO.new
				
				# Dump out useful rack environment variables:
				request = Rack::Request.new(env)
				
				io.puts "#{request.request_method} #{request.url}"
				
				# TODO embed `rack.input` if it's textual?
				# TODO dump and embed `utopia.variables`?
				
				io.puts
				
				REQUEST_KEYS.each do |key|
					value = request.send(key)
					io.puts "request.#{key}: #{value.inspect}"
				end
				
				request.params.each do |key, value|
					io.puts "request.params.#{key}: #{value.inspect}"
				end
				
				io.puts
				
				env.select{|key,_| key.start_with? 'HTTP_'}.each do |key, value|
					io.puts "#{key}: #{value.inspect}"
				end
				
				io.puts
				
				generate_backtrace(io, exception)
				
				return io.string
			end
			
			def attributes_for(exception, env)
				{
					exception: exception.class.name,
					pid: $$,
					cwd: Dir.getwd,
				}
			end
			
			def generate_mail(exception, env)
				mail = Mail.new(
					:from => @from,
					:to => @to,
					:subject => @subject % attributes_for(exception, env)
				)
				
				mail.text_part = Mail::Part.new
				mail.text_part.body = generate_body(exception, env)
			
				if body = extract_body(env) and body.size > 0
					mail.attachments['body.bin'] = body
				end
				
				if @dump_environment
					mail.attachments['environment.yaml'] = YAML::dump(env)
				end

				return mail
			end

			def send_notification(exception, env)
				mail = generate_mail(exception, env)
				
				mail.delivery_method(*@delivery_method) if @delivery_method
				
				mail.deliver
			rescue => mail_exception
				$stderr.puts mail_exception.to_s
				$stderr.puts mail_exception.backtrace
			end

			def extract_body(env)
				if io = env['rack.input']
					io.rewind if io.respond_to?(:rewind)
					io.read
				end
			end
		end
	end
end
