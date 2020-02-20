# frozen_string_literal: true

require 'rack/builder'
require 'rack/test'

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
	
	def binding
		super
	end
end

# Start an interactive console for the web application.
def shell
	call 'utopia:environment'
	
	require 'irb'
	
	Shell.new(self.context).binding.irb
end
