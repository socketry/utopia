# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2026, by Samuel Williams.

require "cgi"
require "uri"

require "protocol/http/request"

require_relative "context"

module Protocol
	module HTTP
		class Request
			alias request_method method
			
			def get?
				self.method == "GET"
			end
			
			def head?
				self.method == "HEAD"
			end
			
			def post?
				self.method == "POST"
			end
			
			def put?
				self.method == "PUT"
			end
			
			def patch?
				self.method == "PATCH"
			end
			
			def delete?
				self.method == "DELETE"
			end
			
			def options?
				self.method == "OPTIONS"
			end
			
			def path_info
				self.path&.split("?", 2)&.first
			end
			
			def path_info=(value)
				if query = self.query
					self.path = "#{value}?#{query}"
				else
					self.path = value
				end
				
				@utopia_arguments = nil
			end
			
			def query
				self.path&.split("?", 2)&.last if self.path&.include?("?")
			end
			
			def arguments
				@utopia_arguments ||= decode_arguments(self.query)
			end
			alias params arguments
			
			def cookies
				@utopia_cookies ||= parse_cookies(self.headers["cookie"])
			end
			
			def host
				self.authority || self.headers["host"]
			end
			alias host_with_port host
			
			def ssl?
				self.scheme == "https"
			end
			
			def base_url
				if self.scheme && self.host
					"#{self.scheme}://#{self.host}"
				else
					""
				end
			end
			
			def user_agent
				self.headers["user-agent"]
			end
			
			def referrer
				self.headers["referer"]
			end
			alias referer referrer
			
			def session
				Utopia::Context.session
			end
			
			def ip
				self.peer&.ip_address
			end
			
			def url
				base_url = self.base_url
				
				if !base_url.empty?
					"#{base_url}#{self.path}"
				else
					self.path
				end
			end
			
			def with(method: self.method, path: self.path, path_info: nil)
				request = self.dup
				request.method = method
				
				if path_info
					if query = self.query
						request.path = "#{path_info}?#{query}"
					else
						request.path = path_info
					end
				else
					request.path = path
				end
				
				request.instance_variable_set(:@utopia_arguments, nil)
				request.instance_variable_set(:@utopia_cookies, nil)
				
				return request
			end
			
			def [] key
				case key
				when "REQUEST_METHOD"
					self.method
				when "PATH_INFO", "REQUEST_PATH"
					self.path_info
				when "QUERY_STRING"
					self.query.to_s
				when "HTTP_HOST"
					self.host
				when "HTTP_USER_AGENT"
					self.user_agent
				when "HTTP_ACCEPT_LANGUAGE"
					self.headers["accept-language"]
				when "HTTP_IF_MODIFIED_SINCE"
					self.headers["if-modified-since"]
				when "HTTP_IF_NONE_MATCH"
					self.headers["if-none-match"]
				when "HTTP_RANGE"
					self.headers["range"]
				else
					if key.is_a?(String) && key.start_with?("HTTP_")
						self.headers[key[5..].downcase.tr("_", "-")]
					else
						self.arguments[key.to_s]
					end
				end
			end
			
			private
			
			def decode_arguments(query)
				arguments = {}
				
				return arguments unless query
				
				URI.decode_www_form(query).each do |key, value|
					values = arguments.fetch(key){arguments[key] = []}
					values << value
				end
				
				arguments.transform_values! do |values|
					if values.size == 1
						values.first
					else
						values
					end
				end
				
				return arguments
			end
			
			def parse_cookies(cookie_header)
				cookies = {}
				
				return cookies unless cookie_header
				
				if cookie_header.respond_to?(:to_str)
					cookie_header = cookie_header.to_str
				else
					cookie_header = cookie_header.to_s
				end
				
				cookie_header.split(/;\s*/).each do |pair|
					key, value = pair.split("=", 2)
					cookies[CGI.unescape(key)] = CGI.unescape(value || "")
				end
				
				return cookies
			end
		end
	end
end
