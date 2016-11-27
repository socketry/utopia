
require "rspec/core/rake_task"

RSpec::Core::RakeTask.new(:test) do |task|
	task.rspec_opts = %w{--require simplecov} if ENV['COVERAGE']
end

task :coverage do
	ENV['COVERAGE'] = 'y'
end
