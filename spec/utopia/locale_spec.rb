#!/usr/bin/env rspec
# Copyright, 2014, by Samuel G. D. Williams. <http://www.codeotaku.com>
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

require 'utopia/locale'

module Utopia::LocaleSpec
	describe Utopia::Locale do
		it "should load from string" do
			locale = Utopia::Locale.load('en-US')
			
			expect(locale.language).to be == 'en'
			expect(locale.country).to be == 'US'
			expect(locale.variant).to be == nil
		end
		
		it "should load from nil and return nil" do
			expect(Utopia::Locale.load(nil)).to be == nil
		end
		
		it "should dump nil and give nil" do
			expect(Utopia::Locale.dump(nil)).to be == nil
		end
		
		it "should dump locale and give string" do
			locale = Utopia::Locale.new('en', 'US')
			
			expect(Utopia::Locale.dump(locale)).to be == 'en-US'
		end
	end
end
