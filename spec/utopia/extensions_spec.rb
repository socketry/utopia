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

require 'utopia/extensions/array_split'
require 'utopia/extensions/date_comparisons'

module Utopia::ExtensionsSpec
	describe Array do
		it "should split in the middle" do
			a = [1, 2, 3, 4, 5]
			
			a, b, c = a.split_at{|x| x == 3}
			
			expect(a).to be == [1, 2]
			expect(b).to be == 3
			expect(c).to be == [4, 5]
		end
		
		it "should not split empty array" do
			expect([].split_at('a')).to be == [[], nil, []]
		end
	end
	
	describe Date do
		it "should be equivalent" do
			time = Time.gm(2000) # 2000-01-01 00:00:00 UTC
			date = time.to_date
			datetime = time.to_datetime
			
			expect(time <=> date).to be == 0
			expect(time <=> datetime).to be == 0
			
			expect(date <=> datetime).to be == 0
			expect(date <=> time).to be == 0
			
			expect(datetime <=> time).to be == 0
			expect(datetime <=> date).to be == 0
		end
		
		it "should compare correctly" do
			today = Date.today
			yesterday = today - 1
			
			expect(today <=> yesterday).to be == 1
			expect(yesterday <=> today).to be == -1
			
			expect(today <=> yesterday.to_datetime).to be == 1
			expect(today <=> yesterday.to_time).to be == 1
			
			expect(today.to_time <=> yesterday.to_datetime).to be == 1
			expect(today.to_time <=> yesterday.to_time).to be == 1
		end
	end
end
