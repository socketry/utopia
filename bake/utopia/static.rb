# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2017-2025, by Samuel Williams.

def generate(output_path: "static")
	require "falcon/server"
	require "async/io"
	require "async/http/endpoint"
	require "async/container"
	require "utopia/application"
	
	application_path = File.join(Dir.pwd, Utopia::Application::CONFIGURATION_PATH)
	container_class = Async::Container::Threaded
	server_port = 9090
	
	app = Utopia::Application.load(application_path)
	
	container = container_class.run(count: 2) do
		Async do
			server = Falcon::Server.new(
				Falcon::Server.middleware(app),
				Async::HTTP::Endpoint.parse("http://localhost:#{server_port}")
			)
			
			server.run
		end
	end
	
	output_path = File.expand_path(output_path, Dir.pwd)
	
	# Delete any existing stuff:
	FileUtils.rm_rf(output_path)
	
	# Copy all public assets:
	FileUtils::Verbose.mkpath(output_path)
	Dir.glob(File.join(Dir.pwd, "public/*")) do |path|
		FileUtils::Verbose.cp_r(path, output_path)
	end
	
	# Generate HTML pages:
	system("wget", "--mirror", "--recursive", "--continue", "--convert-links", "--adjust-extension", "--no-host-directories", "--directory-prefix", output_path.to_s, "http://localhost:#{server_port}")
	
	container.stop
end
