# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2026, by Samuel Williams.

require "traces/provider/utopia/static/middleware"

require "utopia/request"

describe Utopia::Static::Middleware do
	let(:root) {File.expand_path("../../../../utopia/.static", __dir__)}
	let(:middleware) {subject.new(Protocol::HTTP::Middleware::NotFound, root: root)}
	let(:request) {Utopia::Request["GET", "/test.txt"]}
	
	it "traces static responses" do
		traces = []
		
		mock(Traces) do |mock|
			mock.wrap(:trace) do |original, name, attributes: nil, &block|
				traces << [name, attributes]
				original.call(name, attributes: attributes, &block)
			end
		end
		
		path = request.url.path
		response = middleware.respond(request, path, ".txt", "text/plain", localization: nil)
		
		expect(response.status).to be == 200
		expect(traces).to be == [[
			"utopia.static.respond",
			{
				path: path,
				locale: nil,
			},
		]]
	ensure
		response&.close
		middleware.close
	end
end
