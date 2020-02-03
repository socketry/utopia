# frozen_string_literal: true

recipe :generate, description: "Generate a static copy of the site." do |output_path: 'static'|
	require 'falcon/server'
	require 'async/io'
	require 'async/container'
	
	config_path = File.join(Dir.pwd, 'config.ru')
	container_class = Async::Container::Threaded
	server_port = 9090
	
	app, options = Rack::Builder.parse_file(config_path)
	
	container = container_class.run(count: 2) do
		Async do
			server = Falcon::Server.new(app,
				Async::HTTP::Endpoint.parse("http://localhost:#{server_port}")
			)
			
			server.run
		end
	end
	
	output_path = File.expand_path(output_path, Dir.pwd)
	
	# Delete any existing stuff:
	FileUtils.rm_rf(output_path)
	
	# Copy all public assets:
	Dir.glob(File.join(Dir.pwd, 'public/*')).each do |path|
		FileUtils.cp_r(path, output_path)
	end
	
	# Generate HTML pages:
	system("wget", "--mirror", "--recursive", "--continue", "--convert-links", "--adjust-extension", "--no-host-directories", "--directory-prefix", output_path.to_s, "http://localhost:#{server_port}")
	
	container.stop
end
