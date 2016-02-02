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

require 'rack'

module Utopia
	module HTTP
		# A list of commonly used HTTP status codes.
		# For help choosing the right status code, see http://racksburg.com/choosing-an-http-status-code/
		STATUS_CODES = {
			:success => 200,
			:created => 201,
			:accepted => 202,
			:moved => 301,
			:found => 302,
			:see_other => 303,
			:not_modified => 304,
			:redirect => 307,
			:bad_request => 400,
			:unauthorized => 401,
			:forbidden => 403,
			:not_found => 404,
			:not_allowed => 405,
			:unsupported_method => 405,
			:gone => 410,
			:teapot => 418,
			:error => 500,
			:unimplemented => 501,
			:unavailable => 503
		}
		
		# A list of human readable descriptions for a given status code.
		# For a more detailed description, see https://en.wikipedia.org/wiki/List_of_HTTP_status_codes
		STATUS_DESCRIPTIONS = {
			200 => 'OK'.freeze,
			201 => 'Created'.freeze,
			202 => 'Accepted'.freeze,
			203 => 'Non-Authoritive Information'.freeze,
			204 => 'No Content'.freeze,
			205 => 'Reset Content'.freeze,
			206 => 'Partial Content'.freeze,
			300 => 'Multiple Choices'.freeze,
			301 => 'Moved Permanently'.freeze,
			302 => 'Found'.freeze,
			303 => 'See Other'.freeze,
			304 => 'Not Modified'.freeze,
			305 => 'Use Proxy'.freeze,
			307 => 'Temporary Redirect'.freeze,
			308 => 'Permanent Redirect'.freeze,
			400 => 'Bad Request'.freeze,
			401 => 'Permission Denied'.freeze,
			402 => 'Payment Required'.freeze,
			403 => 'Access Forbidden'.freeze,
			404 => 'Resource Not Found'.freeze,
			405 => 'Unsupported Method'.freeze,
			406 => 'Not Acceptable'.freeze,
			408 => 'Request Timeout'.freeze,
			409 => 'Request Conflict'.freeze,
			410 => 'Resource Removed'.freeze,
			416 => 'Byte range unsatisfiable'.freeze,
			500 => 'Internal Server Error'.freeze,
			501 => 'Not Implemented'.freeze,
			503 => 'Service Unavailable'.freeze
		}.merge(Rack::Utils::HTTP_STATUS_CODES)
		
		CONTENT_TYPE = 'Content-Type'.freeze
		LOCATION = 'Location'.freeze
		ACCEPT = 'Accept'.freeze
		
		# Suitable to provide an ordered list of from an Accept or Acccept-Language header.
		def self.prioritised_list(header_value)
			header_value.
				split(',').
				map{|item| item.split(';q=').
					tap{|x| x[1] = (x[1] || 1.0).to_f}
				}.
				sort{|a, b| b[1] <=> a[1]}.
				collect(&:first)
		end
		
		# A small HTTP status wrapper that verifies the status code within a given range.
		class Status
			def initialize(code, valid_range = 100...600)
				if code.is_a? Symbol
					code = STATUS_CODES[code]
				end
				
				unless valid_range.include? code
					raise ArgumentError.new("Status must be in range #{valid_range}, was given #{code}!")
				end
				
				@code = code
			end
			
			def to_i
				@code
			end
			
			def to_s
				STATUS_DESCRIPTIONS[@code] || @code.to_s
			end
			
			# Allow to be used for rack body:
			def each
				yield to_s
			end
		end
	end
end
