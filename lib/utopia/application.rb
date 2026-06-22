# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2026, by Samuel Williams.

require "protocol/http/middleware"
require "protocol/http/middleware/builder"

require_relative "request"
require_relative "response"

module Utopia
	# The protocol-facing entrypoint for a Utopia application.
	#
	# This object accepts {Protocol::HTTP::Request} instances, wraps them in a
	# {Utopia::Request}, dispatches to the Utopia application stack, and normalizes
	# the result back to a {Protocol::HTTP::Response}.
	class Application < Protocol::HTTP::Middleware
		CONFIGURATION_PATH = "config/application.rb".freeze
		
		def self.build(default_app = Response::NotFound, **options, &block)
			builder = Protocol::HTTP::Middleware::Builder.new(default_app)
			builder.build(&block)
			
			return self.new(builder.to_app, **options)
		end
		
		def self.default(**options)
			self.build(**options)
		end
		
		def self.load(path = CONFIGURATION_PATH, **options)
			if File.exist?(path)
				Kernel.load(path)
				
				if Object.const_defined?(:Application, false)
					application = Object.const_get(:Application)
					
					if application.is_a?(Class)
						return application.new(**options)
					else
						return application
					end
				end
			elsif Object.const_defined?(:Application, false)
				application = Object.const_get(:Application)
				
				if application.is_a?(Class)
					return application.new(**options)
				else
					return application
				end
			end
			
			return self.default(**options)
		end
		
		def initialize(delegate, request_class: Request, response_class: Response)
			super(delegate)
			
			@request_class = request_class
			@response_class = response_class
		end
		
		attr :request_class
		attr :response_class
		
		def call(http_request)
			request = @request_class.new(http_request)
			
			return @response_class.wrap(super(request))
		end
	end
end
