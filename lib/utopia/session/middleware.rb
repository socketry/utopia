# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2025-2026, by Samuel Williams.

require "openssl"
require "digest/sha2"
require "console"
require "json"

require "protocol/http/cookie"

require_relative "lazy_hash"
require_relative "serialization"
require_relative "../middleware"
require_relative "../request"
require_relative "../response"

module Utopia
	module Session
		# A middleware which provides a secure client-side session storage using a private symmetric encrpytion key.
		class Middleware < Protocol::HTTP::Middleware
			# Raised when payload processing fails.
			class PayloadError < StandardError
			end
			
			MAXIMUM_SIZE = 1024*32
			
			SECRET_KEY = "UTOPIA_SESSION_SECRET".freeze
			
			SESSION_KEY = "utopia.session".freeze
			CIPHER_ALGORITHM = "aes-256-cbc"
			
			# The session will expire if no requests were made within 24 hours:
			DEFAULT_EXPIRES_AFTER = 3600*24
			
			# At least, the session will be updated every 1 hour:
			DEFAULT_UPDATE_TIMEOUT = 3600
			
			# @param session_name [String] The name of the session cookie.
			# @param secret [String] The secret text used to generate a symmetric encryption key for the cookie data.
			# @param expires_after [Numeric | Nil] The maximum session inactivity in seconds.
			# @param update_timeout [Numeric | Nil] The maximum interval between session cookie updates.
			# @param domain [String | Nil] The domain for which the cookie is valid.
			# @param path [String | Nil] The path for which the cookie is valid.
			# @param max_age [Integer | Nil] The browser cookie lifetime in seconds.
			# @param secure [Boolean] Whether the cookie requires a secure connection.
			# @param http_only [Boolean] Whether client-side scripts may access the cookie.
			# @param same_site [Symbol | String | Boolean | Nil] Controls whether the cookie is sent with cross-site requests.
			# @param partitioned [Boolean] Whether the cookie uses partitioned storage.
			# @param maximum_size [Integer | Nil] The maximum encoded session payload size.
			def initialize(app, session_name: SESSION_KEY, secret: nil, expires_after: DEFAULT_EXPIRES_AFTER, update_timeout: DEFAULT_UPDATE_TIMEOUT, domain: nil, path: "/", max_age: nil, secure: false, http_only: true, same_site: :lax, partitioned: false, maximum_size: MAXIMUM_SIZE)
				super(app)
				
				@session_name = session_name
				@cookie_name = @session_name + ".encrypted"
				
				if secret.nil? or secret.empty?
					raise ArgumentError, "invalid session secret: #{secret.inspect}"
				end
				
				# This generates a 32-byte key suitable for aes.
				@key = Digest::SHA2.digest(secret)
				
				@expires_after = expires_after
				@update_timeout = update_timeout
				
				@cookie_defaults = {
					domain: domain,
					path: path,
					max_age: max_age,
					
					# The SameSite attribute controls when the cookie is sent to the server, from 3rd parties (None), from requests with external referrers (Lax) or from within the site itself (Strict).
					same_site: normalize_same_site(same_site),
					
					# The Secure attribute is meant to keep cookie communication limited to encrypted transmission, directing browsers to use cookies only via secure/encrypted connections. However, if a web server sets a cookie with a secure attribute from a non-secure connection, the cookie can still be intercepted when it is sent to the user by man-in-the-middle attacks. Therefore, for maximum security, cookies with the Secure attribute should only be set over a secure connection.
					secure: secure,
					
					# The HttpOnly attribute directs browsers not to expose cookies through channels other than HTTP (and HTTPS) requests. This means that the cookie cannot be accessed via client-side scripting languages (notably JavaScript), and therefore cannot be stolen easily via cross-site scripting (a pervasive attack technique).
					http_only: http_only,
					partitioned: partitioned,
				}
				
				@serialization = Serialization.new
				@maximum_size = maximum_size
			end
			
			attr :cookie_name
			attr :key
			
			attr :expires_after
			attr :update_timeout
			
			attr :cookie_defaults
			
			# Freeze this object and its internal state.
			# @returns [self] This object.
			def freeze
				return self if frozen?
				
				@cookie_name.freeze
				@key.freeze
				@expires_after.freeze
				@update_timeout.freeze
				@cookie_defaults.freeze
				
				super
			end
			
			# Attach a lazily loaded session to the request, then persist it.
			# @parameter request [Utopia::Request] The request.
			# @returns [Protocol::HTTP::Response] The wrapped application response.
			def call(request)
				request.session = prepare_session(request)
				
				response = Response.wrap(@delegate.call(request))
				
				update_session(request.session, response.headers)
				
				return response
			end
			
			protected
			
			# Normalize a SameSite option to its cookie directive value:
			def normalize_same_site(same_site)
				case same_site
				when false, nil
					return nil
				when :none, "None", :None
					return "None"
				when :lax, "Lax", :Lax
					return "Lax"
				when true, :strict, "Strict", :Strict
					return "Strict"
				else
					raise ArgumentError, "Invalid same_site value: #{same_site.inspect}!"
				end
			end
			
			def prepare_session(request)
				LazyHash.new do
					self.load_session_values(request)
				end
			end
			
			def update_session(session_hash, headers)
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
			def load_session_values(request)
				# Decrypt the data from the user if possible:
				if data = request.cookies[@cookie_name]
					begin
						if values = decrypt(data)
							validate_session!(request, values)
							
							return values
						end
					rescue => error
						Console.error(self, error)
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
				
				headers.add("set-cookie", cookie_header(@cookie_name, cookie))
			end
			
			def cookie_header(name, cookie)
				directives = {}
				
				if domain = cookie[:domain]
					directives["Domain"] = domain
				end
				
				if path = cookie[:path]
					directives["Path"] = path
				end
				
				if max_age = cookie[:max_age]
					directives["Max-Age"] = max_age
				end
				
				if expires = cookie[:expires]
					directives["Expires"] = expires.httpdate
				end
				
				if cookie[:secure]
					directives["Secure"] = true
				end
				
				if cookie[:http_only]
					directives["HttpOnly"] = true
				end
				
				if same_site = cookie[:same_site]
					directives["SameSite"] = same_site
				end
				
				if cookie[:partitioned]
					directives["Partitioned"] = true
				end
				
				return Protocol::HTTP::Cookie.new(name, cookie.fetch(:value), directives).to_s
			end
			
			def encrypt(hash)
				c = OpenSSL::Cipher.new(CIPHER_ALGORITHM)
				c.encrypt
				
				# your pass is what is used to encrypt/decrypt
				c.key = @key
				c.iv = iv = c.random_iv
				
				e = c.update(@serialization.dump(hash))
				e << c.final
				
				return [iv + e].pack("m0")
			end
			
			def decrypt(data)
				if @maximum_size and data.bytesize > @maximum_size
					raise PayloadError, "Session payload size #{data.bytesize}bytes exceeds maximum allowed size #{@maximum_size}bytes!"
				end
				
				payload = data.unpack1("m0")
				iv = payload.byteslice(0, 16)
				e = payload.byteslice(16..)
				
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
end
