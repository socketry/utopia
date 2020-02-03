# frozen_string_literal: true

recipe :deploy, description: 'Prepare the application for start/restart.' do
	# This task is typiclly run after the site is updated but before the server is restarted.
end

recipe :restart, description: 'Restart the application server.' do
	call 'falcon:supervisor:restart'
end

recipe :default, description: 'Start the development server.' do
	call 'utopia:development'
end
