require "bundler/gem_tasks"
require "rspec/core/rake_task"

RSpec::Core::RakeTask.new(:test)

namespace :documentation do
	task :yard do
		sh('yard', '-o', "documentation/public/code")
	end

	task :server do
		Bundler.with_clean_env do
			Dir.chdir('documentation') do
				sh('bundle', 'install', '--quiet')
				sh('bundle', 'exec', 'rake')
			end
		end
	end

	task :static => :yard do
		require 'rackula/command'
		
		Dir.chdir("documentation") do
			Rackula::Command::Top["generate", "--force", "--output-path", "../docs"].invoke
		end
	end
end

task :default => :test
