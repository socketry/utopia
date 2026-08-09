# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2017-2025, by Samuel Williams.

# Generate a static copy of the application.
# @parameter output_path [String] The output path for the generated site.
# @parameter application_path [String] The application configuration path.
# @parameter public_path [String] The public assets path.
# @parameter force [Boolean] Remove the output directory before generating the site.
def generate(output_path: "static", application_path: "config/application.rb", public_path: "public", force: true)
	require "falcon/server"
	require "async/http/endpoint"
	require "async/container"
	require "fileutils"
	require "utopia/application"
	
	application_path = File.expand_path(application_path, Dir.pwd)
	public_path = File.expand_path(public_path, Dir.pwd)
	container_class = Async::Container::Threaded
	server_port = 9090
	
	app = Utopia::Application.load(application_path)
	
	container = container_class.run(count: 1) do
		Async do
			server = Falcon::Server.new(
				Falcon::Server.protocol_middleware(app),
				Async::HTTP::Endpoint.parse("http://localhost:#{server_port}")
			)
			
			server.run
		end
	end
	
	output_path = File.expand_path(output_path, Dir.pwd)
	
	# Delete existing output when explicitly requested:
	if force
		FileUtils.rm_rf(output_path)
	end
	
	# Copy all public assets:
	FileUtils::Verbose.mkpath(output_path)
	Dir.glob(File.join(public_path, "*")) do |path|
		FileUtils::Verbose.cp_r(path, output_path)
	end
	
	begin
		# Generate HTML pages:
		unless system("wget", "--mirror", "--recursive", "--continue", "--convert-links", "--adjust-extension", "--no-host-directories", "--directory-prefix", output_path.to_s, "http://localhost:#{server_port}")
			raise "Static site generation failed!"
		end
	ensure
		container.stop
	end
end
