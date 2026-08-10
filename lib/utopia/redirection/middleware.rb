# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2026, by Samuel Williams.

require_relative "../middleware"
require_relative "../request"
require_relative "../response"

module Utopia
	module Redirection
		# Applies configured request redirections.
		class Middleware < Protocol::HTTP::Middleware
			# Initialize redirection handling.
			# @parameter delegate [Protocol::HTTP::Middleware] The downstream middleware.
			# @parameter builder [Builder] The configured redirection builder.
			def initialize(delegate, builder)
				super(delegate)
				
				@rules = builder.rules
			end
			
			# Build a redirect response for the given rule and location.
			# @parameter rule [Object] The matching redirection rule.
			# @parameter location [String] The redirect destination.
			# @returns [Protocol::HTTP::Response] The redirect response.
			def redirect(rule, location)
				headers = {
					HTTP::LOCATION => location,
					HTTP::CACHE_CONTROL => "max-age=#{rule.max_age}"
				}
				
				return Response[rule.status, headers, []]
			end
			
			# Apply request redirections and invoke the delegate when none match.
			# @parameter request [Utopia::Request] The request.
			# @returns [Protocol::HTTP::Response] The resulting response.
			def call(request)
				# Normalize the path once to remove redundant slashes and dot segments:
				path = Path.create(request.path_info).simplify.to_s
				
				@rules.each do |rule|
					if location = rule.call(path)
						return redirect(rule, location)
					end
				end
				
				return @delegate.call(request)
			end
		end
	end
end
