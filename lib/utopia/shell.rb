# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2020-2022, by Samuel Williams.

require 'rack/builder'
require 'rack/test'
require 'irb'

module Utopia
	# This is designed to be used with the corresponding bake task.
	class Shell
		include Rack::Test::Methods
		
		def initialize(context)
			@context = context
			@app = nil
		end
		
		def app
			@app ||= Rack::Builder.parse_file(
				File.expand_path('config.ru', @context.root)
			).first
		end
		
		def to_s
			self.class.name
		end
		
		def binding
			super
		end
	end
end
