require "bundler/gem_tasks"
require "rspec/core/rake_task"

RSpec::Core::RakeTask.new(:test)

task :documentation do
	sh('yard', '-o', "documentation/public/code")
	
	ENV.delete_if {|key| key =~ /BUNDLE|RUBY/}
	
	Dir.chdir('documentation') do
		sh('bundle', 'install', '--quiet')
		sh('bundle', 'exec', 'rake')
	end
end

task :default => :test
