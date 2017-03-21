
group :development do
	guard :puma, port: 9292 do
		watch('Gemfile.lock')
		watch('config.ru')
		watch(%r{^config|lib|pages/.*})
	end
end

group :test do
	guard :rspec, cmd: 'rspec' do
		watch(%r{^spec/.+_spec\.rb$})
		watch(%r{^lib/(.+)\.rb$}) { |m| 'spec/lib/#{m[1]}_spec.rb' }
		watch('spec/spec_helper.rb') { 'spec' }
		watch(%r{^pages/.*}) { 'spec/website_spec.rb' }
	end
end
