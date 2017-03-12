require "bundler/gem_tasks"
require "rspec/core/rake_task"

RSpec::Core::RakeTask.new(:spec)

task :documentation do
	sh('yard', '-o', "documentation/public/code")
	sh('bundle install')
	sh('cd documentation && rake')
end

task :default => :spec
