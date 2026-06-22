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
		
		# Build a Utopia application stack using the protocol HTTP middleware builder.
		# @parameter default_app [Interface(:call)] The terminal application used when the block does not call `run`.
		# @parameter options [Hash] Options passed to {.new}.
		# @parameter block [Proc] The middleware builder block.
		# @returns [Application] The protocol-facing Utopia application.
		def self.build(default_app = Response::NotFound, **options, &block)
			builder = Protocol::HTTP::Middleware::Builder.new(default_app)
			
			if block
				if block.arity.zero?
					builder.instance_exec(&block)
				else
					block.call(builder)
				end
			end
			
			return self.new(builder.to_app, **options)
		end
		
		# Build the default Utopia application.
		# @parameter options [Hash] Options passed to {.build}.
		# @returns [Application] The default protocol-facing Utopia application.
		def self.default(**options)
			self.build(**options)
		end
		
		# Load a Utopia application from a conventional configuration file.
		#
		# If the file defines a top-level `Application` constant, it will be
		# returned directly. If the constant is a class, it will be instantiated.
		# If the file does not exist, or does not define `Application`, the default
		# application is returned.
		#
		# @parameter path [String] The application configuration path.
		# @parameter options [Hash] Options passed to the application constructor.
		# @returns [Interface(:call)] The loaded protocol-facing application.
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
		
		# Initialize the protocol-facing application boundary.
		# @parameter delegate [Interface(:call)] The Utopia application stack.
		# @parameter request_class [Class] The request wrapper class.
		# @parameter response_class [#wrap] The response normalization object.
		def initialize(delegate, request_class: Request, response_class: Response)
			super(delegate)
			
			@request_class = request_class
			@response_class = response_class
		end
		
		# @attribute [Class] The request wrapper class.
		attr :request_class
		
		# @attribute [#wrap] The response normalization object.
		attr :response_class
		
		# Process a protocol HTTP request.
		# @parameter http_request [Protocol::HTTP::Request] The incoming protocol request.
		# @returns [Protocol::HTTP::Response] The normalized protocol response.
		def call(http_request)
			request = @request_class.new(http_request)
			
			return @response_class.wrap(super(request))
		end
	end
end
