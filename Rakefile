require "bundler/gem_tasks"
require "rspec/core/rake_task"

RSpec::Core::RakeTask.new(:test)

require 'rubocop/rake_task'
RuboCop::RakeTask.new(:rubocop) do |t|
  t.patterns = ['{benchmarks,documentation,lib,setup,spec}/**/*.rb'] +
               %w[Gemfile Rakefile utopia.gemspec]
  t.options = %w[--display-cop-names --extra-details --display-style-guide]
end

task :documentation do
	sh('yard', '-o', "documentation/public/code")
	
	Bundler.with_clean_env do	
		Dir.chdir('documentation') do
			sh('bundle', 'install', '--quiet')
			sh('bundle', 'exec', 'rake')
		end
	end
end

task :default => :test
