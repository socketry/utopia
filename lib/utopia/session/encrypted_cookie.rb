# Copyright (c) 2010 Samuel Williams. Released under the GNU GPLv3.
#
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
# 
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
# 
# You should have received a copy of the GNU General Public License
# along with this program.  If not, see <http://www.gnu.org/licenses/>.

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