# frozen_string_literal: true

include Rack::Test::Methods

# Start an interactive console for the web application.
def console
	call 'utopia:environment'
	
	require 'irb'
	require 'rack/test'
	
	ARGV.clear
	IRB.start
end

private

def app
	@app ||= Rack::Builder.parse_file(
		File.expand_path('config.ru', context.root)
	).first
end
