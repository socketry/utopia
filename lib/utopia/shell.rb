# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2020-2025, by Samuel Williams.

require "protocol/http/request"
require_relative "application"
require "irb"

module Utopia
	# This is designed to be used with the corresponding bake task.
	class Shell
		def initialize(context)
			@context = context
			@app = nil
		end
		
		def app
			@app ||= Application.load(File.expand_path(Application::CONFIGURATION_PATH, @context.root))
		end
		
		def get(path, headers = nil)
			app.call(Protocol::HTTP::Request["GET", path, headers])
		end
		
		def post(path, headers = nil, body = nil)
			app.call(Protocol::HTTP::Request["POST", path, headers, body])
		end
		
		def to_s
			self.class.name
		end
		
		def binding
			super
		end
	end
end
