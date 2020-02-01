# frozen_string_literal: true

desc 'Run by git post-update hook when deployed to a web server'
task :deploy do
	# This task is typiclly run after the site is updated but before the server is restarted.
end

desc 'Restart the application server'
task :restart do
	if falcon = `which falcon`.chomp! and File.exist?("supervisor.ipc")
		sh(falcon, 'supervisor', 'restart')
	end
end
