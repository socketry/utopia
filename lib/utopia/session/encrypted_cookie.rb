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

module Utopia
	module Session

		class EncryptedCookie
			RACK_SESSION = "rack.session"
			RACK_SESSION_OPTIONS = "rack.session.options"

			def initialize(app, options={})
				@app = app
				@cookie = options[:cookie] || (RACK_SESSION + ".encrypted")
				@secret = Digest::SHA256.digest(options[:secret])

				@default_options = {
					:domain => nil,
					:path => "/",
					:expires_after => nil
				}.merge(options)
			end

			def call(env)
				original_session = load_session(env).dup

				status, headers, body = @app.call(env)

				if original_session != env[RACK_SESSION]
					commit_session(env, status, headers, body)
				end

				return [status, headers, body]
			end

			private

			def load_session(env)
				session = {}

				request = Rack::Request.new(env)
				data = request.cookies[@cookie]

				if data
					session = decrypt(data) rescue session
				end

				env[RACK_SESSION] = session
				env[RACK_SESSION_OPTIONS] = @default_options.dup

				return session
			end
			
			def commit_session(env, status, headers, body)
				session = env[RACK_SESSION]

				data = encrypt(session)

				if data.size > (1024 * 4)
					env["rack.errors"].puts "Error: #{self.class.name} data exceeds 4K. Content Dropped!"
				else
					options = env[RACK_SESSION_OPTIONS]
					cookie = {:value => data}
					cookie[:expires] = Time.now + options[:expires_after] unless options[:expires_after].nil?

					Rack::Utils.set_cookie_header!(headers, @cookie, cookie.merge(options))
				end
			end
			
			def encrypt(hash)
				c = OpenSSL::Cipher::Cipher.new("aes-256-cbc")
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

				c = OpenSSL::Cipher::Cipher.new("aes-256-cbc")
				c.decrypt

				c.key = @secret
				c.iv = iv

				d = c.update(e)
				d << c.final

				return Marshal.load(d)
			end
		end
		
	end
end