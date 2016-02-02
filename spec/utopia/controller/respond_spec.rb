#!/usr/bin/env rspec

# Copyright, 2012, by Samuel G. D. Williams. <http://www.codeotaku.com>
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

require 'rack/mock'

require 'utopia/controller'

module Utopia::Controller::RespondSpec
	describe Utopia::Controller::Respond::Converters do
		let(:text_html_converter) {Utopia::Controller::Respond::Converter.new("text/html", lambda {})}
		let(:text_plain_converter) {Utopia::Controller::Respond::Converter.new("text/plain", lambda {})}
		
		it "should give the correct converter when specified completely" do
			subject << text_html_converter
			subject << text_plain_converter
			
			expect(subject.for(["text/plain", "text/*", "*/*"])).to be text_plain_converter
			
			expect(subject.for(["text/html", "text/*", "*/*"])).to be text_html_converter
		end
		
		it "should match the wildcard subtype converter" do
			subject << text_html_converter
			subject << text_plain_converter
			
			expect(subject.for(["text/*", "*/*"])).to be text_html_converter
			
			expect(subject.for(["*/*"])).to be text_html_converter
		end
		
		it "should fail to match if no media types match" do
			subject << text_plain_converter
			
			expect(subject.for(["application/json"])).to be nil
		end
		
		it "should fail to match if no media types specified" do
			expect(subject.for(["text/*", "*/*"])).to be nil
		end
	end
end
