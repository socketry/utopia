# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2016-2023, by Samuel Williams.

require 'website'
require 'benchmark/http'

describe "website" do
	include_context AServer
	
	let(:timeout) {10}
	let(:spider) {Benchmark::HTTP::Spider.new(depth: 128)}
	let(:statistics) {Benchmark::HTTP::Statistics.new}
	
	it "should be responsive" do
		spider.fetch(statistics, client, endpoint.url) do |method, uri, response|
			if response.failure?
				Console.logger.error(endpoint) {"#{method} #{uri} -> #{response.status}"}
			end
		end.wait
		
		statistics.print
		
		expect(statistics.samples).to be(:any?)
		expect(statistics.failed).to be(:zero?)
	end
end
