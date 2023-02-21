# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2016-2023, by Samuel Williams.
# Copyright, 2017, by Huba Nagy.

require 'utopia/setup'

describe Utopia::Setup do
	let(:config_root) {File.expand_path('setup_spec/config', __dir__)}
	let(:setup) {subject.new(config_root)}
	
	let(:environment) {Variant::Environment.instance}
	let(:sequence) {Array.new}
	
	it "should load specified environment" do
		environment.with({'VARIANT' => 'production'}) do
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
			File.expand_path('lib', setup.site_root)
		)
		
		setup.send(:add_load_path, 'lib')
	end
end
