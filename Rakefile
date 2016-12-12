require "bundler/gem_tasks"
require "rspec/core/rake_task"

RSpec::Core::RakeTask.new(:spec) do |task|
	begin
		require('simplecov/version')
		task.rspec_opts = %w{--require simplecov} if ENV['COVERAGE']
	rescue LoadError
	end
end

task :documentation do
	sh('bundle install')
	sh('cd documentation && rake')
end

task :default => :spec
