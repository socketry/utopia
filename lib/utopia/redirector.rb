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

require_relative 'middleware'

module Utopia
	class FailedRequestError < StandardError
		def initialize(resource_path, resource_status, error_path, error_status)
			@resource_path = resource_path
			@resource_status = resource_status

			@error_path = error_path
			@error_status = error_status
		end

		def to_s
			"Requested resource #{@resource_path} resulted in a #{@resource_status} error. Requested error handler #{@error_path} resulted in a #{@error_status} error."
		end
	end

	class Redirector
		# This redirects directories to the directory + 'index' 
		DIRECTORY_INDEX = [/^(.*)\/$/, lambda{|prefix| [307, {HTTP::LOCATION => "#{prefix}index"}, []]}]
		
		# Redirects a whole source tree to a destination tree, given by the roots.
		def self.moved(source_root, destination_root)
			return [
				/^#{Regexp.escape(source_root)}(.*)$/,
				lambda do |match|
					[301, {HTTP::LOCATION => (destination_root + match[1]).to_s}, []]
				end
			]
		end
		
		def self.starts_with(source_root, destination_uri)
			return [
				/^#{Regexp.escape(source_root)}/,
				destination_uri
			]
		end
		
		private
		
		def normalize_strings(strings)
			normalized = {}
			
			strings.each_pair do |key, value|
				if Array === key
					key.each { |s| normalized[s] = value }
				else
					normalized[key] = value
				end
			end
			
			return normalized
		end

		def normalize_patterns(patterns)
			normalized = []
			
			patterns.each do |pattern|
				uri = pattern.pop
				
				pattern.each do |key|
					normalized.push([key, uri])
				end
			end
			
			return normalized
		end

		public
		
		def initialize(app, **options)
			@app = app

			@strings = options[:strings] || {}
			@patterns = options[:patterns] || []

			@patterns.collect! do |rule|
				if Symbol === rule[0]
					self.class.send(*rule)
				else
					rule
				end
			end

			@strings = normalize_strings(@strings)
			@patterns = normalize_patterns(@patterns)

			@errors = options[:errors]
		end

		def redirect(uri, match_data)
			if uri.respond_to? :call
				return uri.call(match_data)
			else
				return [301, {HTTP::LOCATION => uri.to_s}, []]
			end
		end

		def call(env)
			base_path = env[Rack::PATH_INFO]

			if uri = @strings[base_path]
				return redirect(@strings[base_path], base_path)
			end

			@patterns.each do |pattern, uri|
				if match_data = pattern.match(base_path)
					result = redirect(uri, match_data)

					return result if result != nil
				end
			end

			response = @app.call(env)

			if @errors && response[0] >= 400 && uri = @errors[response[0]]
				error_request = env.merge(Rack::PATH_INFO => uri, Rack::REQUEST_METHOD => Rack::GET)
				error_response = @app.call(error_request)

				if error_response[0] >= 400
					raise FailedRequestError.new(env[Rack::PATH_INFO], response[0], uri, error_response[0])
				else
					# Feed the error code back with the error document
					error_response[0] = response[0]
					return error_response
				end
			else
				return response
			end
		end
	end
end
