#!/usr/bin/env rspec

# Copyright, 2015, by Samuel G. D. Williams. <http://www.codeotaku.com>
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

require 'utopia/path/matcher'

module Utopia::Path::MatcherSpec
	describe Utopia::Path::Matcher do
		it "should match strings" do
			path = Utopia::Path['users/20/edit']
			matcher = Utopia::Path::Matcher[users: 'users']
			
			match_data = matcher.match(path)
			expect(match_data).to_not be nil
			
			expect(match_data.post_match).to be == Utopia::Path['20/edit']
		end
		
		it "shouldn't match strings" do
			path = Utopia::Path['users/20/edit']
			matcher = Utopia::Path::Matcher[accounts: 'accounts']
			
			match_data = matcher.match(path)
			expect(match_data).to be nil
		end
		
		it "shouldn't match integer" do
			path = Utopia::Path['users/20/edit']
			matcher = Utopia::Path::Matcher[id: Integer]
			
			match_data = matcher.match(path)
			expect(match_data).to be nil
		end
		
		it "should match regexps" do
			path = Utopia::Path['users/20/edit']
			matcher = Utopia::Path::Matcher[users: 'users', id: Integer, action: String]
			
			match_data = matcher.match(path)
			expect(match_data).to_not be_falsey
			
			expect(match_data[:users]).to be == 'users'
			expect(match_data[:id]).to be == 20
			expect(match_data[:action]).to be == 'edit'
		end
	end
end
