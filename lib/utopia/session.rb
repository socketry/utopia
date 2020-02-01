# frozen_string_literal: true

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

require 'openssl'
require 'securerandom'
require 'digest/sha2'

require 'json'

require_relative 'session/lazy_hash'
require_relative 'session/serialization'

module Utopia
	# A middleware which provides a secure client-side session storage using a private symmetric encrpytion key.
	class Session
		class PayloadError < StandardError
		end
		
		MAXIMUM_SIZE = 1024*32
		
		SECRET_KEY = 'UTOPIA_SESSION_SECRET'.freeze
		
		RACK_SESSION = "rack.session".freeze
		CIPHER_ALGORITHM = "aes-256-cbc"
		
		# The session will expire if no requests were made within 24 hours:
		DEFAULT_EXPIRES_AFTER = 3600*24
		
		# At least, the session will be updated every 1 hour:
		DEFAULT_UPDATE_TIMEOUT = 3600
		
		# @param session_name [String] The name of the session cookie.
		# @param secret [Array] The secret text used to generate a symetric encryption key for the coookie data.
		# @param expires_after [String] The cache-control header to set for static content.
		# @param options [Hash<Symbol,Object>] Additional defaults used for generating the cookie by `Rack::Utils.set_cookie_header!`.
		def initialize(app, session_name: RACK_SESSION, secret: nil, expires_after: DEFAULT_EXPIRES_AFTER, update_timeout: DEFAULT_UPDATE_TIMEOUT, secure: false, maximum_size: MAXIMUM_SIZE, **options)
			@app = app
			
			@session_name = session_name
			@cookie_name = @session_name + ".encrypted"
			
			if secret.nil? or secret.empty?
				secret = SecureRandom.hex(32)
				warn "#{self.class} secret is #{secret.inspect}, generating transient secret key!" if $VERBOSE
			end
			
			# This generates a 32-byte key suitable for aes.
			@key = Digest::SHA2.digest(secret)
			
			@expires_after = expires_after
			@update_timeout = update_timeout
			
			@cookie_defaults = {
				domain: nil,
				path: "/",
				# The Secure attribute is meant to keep cookie communication limited to encrypted transmission, directing browsers to use cookies only via secure/encrypted connections. However, if a web server sets a cookie with a secure attribute from a non-secure connection, the cookie can still be intercepted when it is sent to the user by man-in-the-middle attacks. Therefore, for maximum security, cookies with the Secure attribute should only be set over a secure connection.
				secure: secure,
				# The HttpOnly attribute directs browsers not to expose cookies through channels other than HTTP (and HTTPS) requests. This means that the cookie cannot be accessed via client-side scripting languages (notably JavaScript), and therefore cannot be stolen easily via cross-site scripting (a pervasive attack technique).
				http_only: true,
			}.merge(options)
			
			@serialization = Serialization.new
			@maximum_size = maximum_size
		end
		
		attr :cookie_name
		attr :key
		
		attr :expires_after
		attr :update_timeout
		
		attr :cookie_defaults
		
		def freeze
			return self if frozen?
			
			@cookie_name.freeze
			@key.freeze
			@expires_after.freeze
			@update_timeout.freeze
			@cookie_defaults.freeze
			
			super
		end

		def call(env)
			session_hash = prepare_session(env)

			status, headers, body = @app.call(env)

			update_session(env, session_hash, headers)

			return [status, headers, body]
		end
		
		protected
		
		def prepare_session(env)
			env[RACK_SESSION] = LazyHash.new do
				self.load_session_values(env)
			end
		end
		
		def update_session(env, session_hash, headers)
			if session_hash.needs_update?(@update_timeout)
				values = session_hash.values
				
				values[:updated_at] = Time.now.utc
				
				data = encrypt(session_hash.values)
				
				commit(data, values[:updated_at], headers)
			end
		end
		
		# Constructs a valid session for the given request. These fields must match as per the checks performed in `valid_session?`:
		def build_initial_session(request)
			{
				user_agent: request.user_agent,
				created_at: Time.now.utc,
				updated_at: Time.now.utc,
			}
		end
		
		# Load session from user supplied cookie. If the data is invalid or otherwise fails validation, `build_iniital_session` is invoked.
		# @return hash of values.
		def load_session_values(env)
			request = Rack::Request.new(env)
			
			# Decrypt the data from the user if possible:
			if data = request.cookies[@cookie_name]
				begin
					if values = decrypt(data)
						validate_session!(request, values)
						
						return values
					end
				rescue => error
					request.logger&.error(error)
				end
			end
			
			# If we couldn't create a session
			return build_initial_session(request)
		end
		
		def validate_session!(request, values)
			if values[:user_agent] != request.user_agent
				raise PayloadError, "Invalid session because supplied user agent #{request.user_agent.inspect} does not match session user agent #{values[:user_agent].inspect}!"
			end

			if expires_at = expires(values[:updated_at])
				if expires_at < Time.now.utc
					raise PayloadError, "Expired session cookie, user agent submitted a cookie that should have expired at #{expires_at}."
				end
			end
			
			return true
		end
		
		def expires(updated_at=Time.now.utc)
			if @expires_after
				return updated_at + @expires_after
			end
		end
		
		def commit(value, updated_at, headers)
			cookie = {
				value: value,
				expires: expires(updated_at)
			}.merge(@cookie_defaults)
			
			Rack::Utils.set_cookie_header!(headers, @cookie_name, cookie)
		end
		
		def encrypt(hash)
			c = OpenSSL::Cipher.new(CIPHER_ALGORITHM)
			c.encrypt
			
			# your pass is what is used to encrypt/decrypt
			c.key = @key
			c.iv = iv = c.random_iv
			
			e = c.update(@serialization.dump(hash))
			e << c.final
			
			return [iv, e].pack("m16m*")
		end
		
		def decrypt(data)
			if @maximum_size and data.bytesize > @maximum_size
				raise PayloadError, "Session payload size #{data.bytesize}bytes exceeds maximum allowed size #{@maximum_size}bytes!"
			end
			
			iv, e = data.unpack("m16m*")
			
			c = OpenSSL::Cipher.new(CIPHER_ALGORITHM)
			c.decrypt
			
			c.key = @key
			c.iv = iv
			
			d = c.update(e)
			d << c.final
			
			return @serialization.load(d)
		end
	end
end
