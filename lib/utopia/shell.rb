# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2020-2025, by Samuel Williams.

require "protocol/http/request"
require_relative "application"
require "irb"

module Utopia
	# This is designed to be used with the corresponding bake task.
	class Shell
		# Initialize a shell for a Bake context.
		# @parameter context [Bake::Context] The context that provides the application root.
		def initialize(context)
			@context = context
			@app = nil
		end
		
		# Load the configured application on first access.
		# @returns [Application] The application middleware.
		def app
			@app ||= Application.load(File.expand_path(Application::CONFIGURATION_PATH, @context.root))
		end
		
		# Perform a GET request.
		# @parameter path [Utopia::Path | String] The path.
		# @parameter headers [Hash] The headers.
		# @returns [Protocol::HTTP::Response] The application response.
		def get(path, headers = nil)
			app.call(Protocol::HTTP::Request["GET", path, headers])
		end
		
		# Perform a POST request.
		# @parameter path [Utopia::Path | String] The path.
		# @parameter headers [Hash] The headers.
		# @parameter body [Protocol::HTTP::Body::Readable | nil] The request body.
		# @returns [Protocol::HTTP::Response] The application response.
		def post(path, headers = nil, body = nil)
			app.call(Protocol::HTTP::Request["POST", path, headers, body])
		end
		
		# Convert this object to a string.
		# @returns [String] The resulting string.
		def to_s
			self.class.name
		end
		
		# Expose this shell's binding to IRB.
		# @returns [Binding] The shell binding.
		def binding
			super
		end
	end
end
