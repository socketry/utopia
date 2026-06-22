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
		# @parameter block [Proc] The middleware builder block.
		# @returns [Application] The protocol-facing Utopia application.
		def self.build(default_app = Response::NotFound, &block)
			builder = Protocol::HTTP::Middleware::Builder.new(default_app)
			
			if block
				if block.arity.zero?
					builder.instance_exec(&block)
				else
					block.call(builder)
				end
			end
			
			return self.new(builder.to_app)
		end
		
		# Build the default Utopia application.
		# @returns [Application] The default protocol-facing Utopia application.
		def self.default
			self.build
		end
		
		# Load a Utopia application from a conventional configuration file.
		#
		# If the file defines an `Application` constant, it will be returned
		# directly. If the constant is a class, it will be instantiated.
		# If the file does not exist, or does not define `Application`, the default
		# application is returned.
		#
		# @parameter path [String] The application configuration path.
		# @parameter options [Hash] Options passed to the application constructor.
		# @returns [Interface(:call)] The loaded protocol-facing application.
		def self.load(path = CONFIGURATION_PATH, **options)
			if File.exist?(path)
				top = Module.new
				top.class_eval(File.read(path), path)
				
				if top.const_defined?(:Application, false)
					application = top.const_get(:Application)
					
					if application.is_a?(Class)
						return application.new(**options)
					else
						return application
					end
				end
			end
			
			return self.default
		end
		
		# Initialize the protocol-facing application boundary.
		# @parameter delegate [Interface(:call)] The Utopia application stack.
		def initialize(delegate)
			super(delegate)
		end
		
		# Process a protocol HTTP request.
		# @parameter http_request [Protocol::HTTP::Request] The incoming protocol request.
		# @returns [Protocol::HTTP::Response] The normalized protocol response.
		def call(http_request)
			request = Request.new(http_request)
			
			return Response.wrap(super(request))
		end
	end
end
