# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2016-2026, by Samuel Williams.
# Copyright, 2017, by Huba Nagy.

require "fileutils"
require "sus/fixtures/temporary_directory_context"
require "utopia/setup"

describe Utopia::Setup do
	include Sus::Fixtures::TemporaryDirectoryContext
	
	let(:setup) {subject.new(root)}
	
	let(:environment) {Variant::Environment.instance}
	let(:sequence) {Array.new}
	
	it "should load specified environment" do
		environment.with({"VARIANT" => "production"}) do
			mock(setup) do |mock|
				mock.replace(:load_environment) do |environment|
					sequence << environment
				end
			end
			
			setup.send(:apply_environment)
		end
		
		expect(sequence).to be == [:environment, :production]
	end
	
	it "should load default environment" do
		environment.with({}) do
			mock(setup) do |mock|
				mock.replace(:load_environment) do |environment|
					sequence << environment
				end
			end
			
			setup.send(:apply_environment)
		end
		
		expect(sequence).to be == [:environment, :development]
	end
	
	it "should add load path" do
		expect($LOAD_PATH).to receive(:<<).with(
			File.expand_path("lib", setup.site_root)
		)
		
		setup.send(:add_load_path, "lib")
	end
	
	it "resolves the configuration root" do
		expect(setup.config_root).to be == File.join(root, "config")
	end
	
	[:production, :staging, :development, :testing].each do |variant|
		it "identifies the configured variant", unique: variant do
			environment.with({"UTOPIA_VARIANT" => variant.to_s}) do
				expect(setup).to be(:"#{variant}?")
			end
		end
	end
	
	it "loads environment variables without replacing existing values" do
		configuration_root = File.join(root, "config")
		FileUtils.mkdir_p(configuration_root)
		
		existing_key = "UTOPIA_SETUP_EXISTING"
		new_key = "UTOPIA_SETUP_NEW"
		previous_values = {
			existing_key => ENV[existing_key],
			new_key => ENV[new_key],
		}
		
		ENV[existing_key] = "existing"
		ENV.delete(new_key)
		
		File.write(File.join(configuration_root, "environment.yaml"), YAML.dump(
			existing_key => "replacement",
			new_key => "new",
		))
		
		loaded = subject.new(root).send(:load_environment, :environment)
		
		expect(loaded).to be == true
		expect(ENV[existing_key]).to be == "existing"
		expect(ENV[new_key]).to be == "new"
	ensure
		previous_values.each do |key, value|
			if value
				ENV[key] = value
			else
				ENV.delete(key)
			end
		end
	end
	
	it "rejects repeated global setup" do
		previous_setup = Utopia.instance_variable_get(:@setup)
		Utopia.instance_variable_set(:@setup, Object.new)
		
		expect do
			Utopia.setup(root)
		end.to raise_exception(RuntimeError, message: be =~ /already setup/)
	ensure
		Utopia.instance_variable_set(:@setup, previous_setup)
	end
end
