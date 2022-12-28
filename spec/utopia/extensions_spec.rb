# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2014-2022, by Samuel Williams.

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
