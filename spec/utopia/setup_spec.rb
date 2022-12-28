# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2016-2020, by Samuel Williams.
# Copyright, 2017, by Huba Nagy.

require 'utopia/setup'

RSpec.describe Utopia::Setup do
	let(:config_root) {File.expand_path('setup_spec/config', __dir__)}
	subject{Utopia::Setup.new(config_root)}
	
	let(:environment) {Variant::Environment.instance}
	
	it "should load specified environment" do
		environment.with({'VARIANT' => 'production'}) do
			expect(subject).to receive(:load_environment).with(:environment).ordered
			expect(subject).to receive(:load_environment).with(:production).ordered
			subject.send(:apply_environment)
		end
	end
	
	it "should load default environment" do
		environment.with({}) do
			stub_const("ENV", {})
			expect(subject).to receive(:load_environment).with(:environment).ordered
			expect(subject).to receive(:load_environment).with(:development).ordered
		end
		
		subject.send(:apply_environment)
	end
	
	it "should add load path" do
		expect($LOAD_PATH).to receive(:<<).with(
			File.expand_path('lib', subject.site_root)
		)
		
		subject.send(:add_load_path, 'lib')
	end
end
