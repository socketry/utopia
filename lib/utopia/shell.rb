# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2020-2025, by Samuel Williams.

require "rack/builder"
require "rack/test"
require "irb"

module Utopia
	# This is designed to be used with the corresponding bake task.
	class Shell
		include Rack::Test::Methods
		
		# Initialize a shell for a Bake context.
		# @parameter context [Bake::Context] The context that provides the application root.
		def initialize(context)
			@context = context
			@app = nil
		end
		
		# Load the configured application on first access.
		# @returns [Application] The application middleware.
		def app
			@app ||= Rack::Builder.parse_file(
				File.expand_path("config.ru", @context.root)
			).first
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
