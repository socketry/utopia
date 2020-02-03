
# frozen_string_literal: true

recipe :deploy, description: 'Prepare the application for start/restart.' do
	# This task is typiclly run after the site is updated but before the server is restarted.
end

recipe :restart, description: 'Restart the application server.' do
	if falcon = `which falcon`.chomp! and File.exist?("supervisor.ipc")
		sh(falcon, 'supervisor', 'restart')
	end
end
