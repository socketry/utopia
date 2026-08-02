# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2026, by Samuel Williams.

require "protocol/http/request"
require "utopia/application"

module ProtocolApplication
	def cookies
		@cookies ||= {}
	end
	
	def headers
		@headers ||= {}
	end
	
	attr :last_request
	attr :last_response
	
	def get(path, headers = {})
		self.request("GET", path, headers)
	end
	
	def post(path, headers = {})
		self.request("POST", path, headers)
	end
	
	def request(method, path, headers = {})
		request_headers = self.headers.merge(headers)
		
		unless cookies.empty?
			request_headers["cookie"] = cookies.map{|key, value| "#{key}=#{value}"}.join("; ")
		end
		
		@last_request = Protocol::HTTP::Request[method, path, request_headers]
		@last_response = app.call(@last_request)
		@body_read = false
		@body = nil
		
		store_cookies(@last_response.headers["set-cookie"])
		
		return @last_response
	end
	
	def body
		unless @body_read
			@body = @last_response.read
			@body_read = true
		end
		
		return @body
	end
	
	def header(name, value)
		headers[name.downcase] = value
	end
	
	def set_cookie(cookie)
		name, value = cookie.split(";", 2).first.split("=", 2)
		cookies[name] = value
	end
	
	private
	
	def store_cookies(values)
		Array(values).each do |cookie|
			self.set_cookie(cookie)
		end
	end
end
