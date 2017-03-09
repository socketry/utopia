require "bundler/gem_tasks"
require "rspec/core/rake_task"

RSpec::Core::RakeTask.new(:spec)

task :documentation do
	sh('bundle install')
	sh('cd documentation && rake')
end

task :default => :spec
