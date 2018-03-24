# Copyright, 2018, by Samuel G. D. Williams. <http://www.codeotaku.com>
# 
# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:
# 
# The above copyright notice and this permission notice shall be included in
# all copies or substantial portions of the Software.
# 
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
# THE SOFTWARE.

require 'utopia/setup'

RSpec.describe Utopia::Setup do
	let(:config_root) {File.expand_path('setup_spec/config', __dir__)}
	subject{Utopia::Setup.new(config_root)}
	
	it "should load specified environment" do
		stub_const("Utopia::Setup::ENV", {'UTOPIA_ENV' => 'production'})
		
		expect(subject).to receive(:load_environment).with('production')
		
		subject.apply_environment
	end
	
	it "should load default environment" do
		stub_const("Utopia::Setup::ENV", {})
		
		expect(subject).to receive(:load_environment).with('environment')
		
		subject.apply_environment
	end
	
	it "should add load path" do
		subject.add_load_path('lib')
		
		expect($LOAD_PATH).to include(File.expand_path('lib', subject.site_root))
	end
end
