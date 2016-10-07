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
require 'digest/sha2'

require_relative 'session/lazy_hash'

module Utopia
	# Stores all session data client side using a private symmetric encrpytion key.
	class Session
		RACK_SESSION = "rack.session".freeze
		
		def initialize(app, **options)
			@app = app
			@cookie_name = options.delete(:cookie_name) || (RACK_SESSION + ".encrypted")

			@secret = options.delete(:secret)

			@options = {
				:domain => nil,
				:path => "/",
				:expires_after => nil
			}.merge(options)
		end

		def call(env)
			session_hash = prepare_session(env)

			status, headers, body = @app.call(env)

			if session_hash.changed?
				commit(session_hash.values, headers)
			end

			return [status, headers, body]
		end
		
		protected
		
		def prepare_session(env)
			env[RACK_SESSION] = LazyHash.new do
				self.load_session_values(env)
			end
		end
		
		# Constructs a valid session for the given request. These fields must match as per the checks performed in `valid_session?`:
		def build_initial_session(request)
			{
				request_ip: request.ip,
				request_user_agent: request.user_agent,
			}
		end
		
		# Load session from user supplied cookie. If the data is invalid or otherwise fails validation, `build_iniital_session` is invoked.
		# @return hash of values.
		def load_session_values(env)
			request = Rack::Request.new(env)
			
			# Decrypt the data from the user if possible:
			if data = request.cookies[@cookie_name]
				if values = decrypt(data) and valid_session?(request, values)
					return values
				end
			end
			
			# If we couldn't create a session
			return build_initial_session(request)
		end
		
		def valid_session?(request, values)
			if values[:request_ip] != request.ip
				return false
			end
			
			if values[:request_user_agent] != request.user_agent
				return false
			end
			
			return true
		end
		
		def commit(values, headers)
			data = encrypt(values)
			
			cookie = {:value => data}
			
			cookie[:expires] = Time.now + @options[:expires_after] unless @options[:expires_after].nil?
			
			Rack::Utils.set_cookie_header!(headers, @cookie_name, cookie.merge(@options))
		end
		
		CIPHER_ALGORITHM = "aes-256-cbc"
		
		def encrypt(hash)
			c = OpenSSL::Cipher.new(CIPHER_ALGORITHM)
			c.encrypt
			
			# your pass is what is used to encrypt/decrypt
			c.key = @secret
			c.iv = iv = c.random_iv
			
			e = c.update(Marshal.dump(hash))
			e << c.final
			
			return [iv, e].pack("m16m*")
		end
		
		def decrypt(data)
			iv, e = data.unpack("m16m*")
			
			c = OpenSSL::Cipher.new(CIPHER_ALGORITHM)
			c.decrypt
			
			c.key = @secret
			c.iv = iv
			
			d = c.update(e)
			d << c.final
			
			return Marshal.load(d)
		end
	end
end
