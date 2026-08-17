# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2026, by Samuel Williams.

require "traces/provider/utopia"

require "utopia/content/link"
require "utopia/localization/preferences"
require "utopia/request"

describe Utopia::Content::Middleware do
	let(:middleware) do
		subject.new(
			Protocol::HTTP::Middleware::NotFound,
			root: File.expand_path(".", __dir__),
		)
	end
	
	let(:request) {Utopia::Request["GET", "/example"]}
	let(:localization) do
		Utopia::Localization::Preferences.new(
			all_locales: ["en"],
			preferred_locales: ["en"],
			default_locale: "en",
		)
	end
	
	it "traces content responses" do
		traces = []
		
		mock(Traces) do |mock|
			mock.wrap(:trace) do |original, name, attributes: nil, &block|
				traces << [name, attributes]
				original.call(name, attributes: attributes, &block)
			end
		end
		
		link = Utopia::Content::Link.new(:virtual, "example", "en", "/example", uri: "/target")
		response = middleware.respond(link, request, localization: localization)
		
		expect(response.status).to be == 307
		expect(traces).to be == [[
			"utopia.content.respond",
			{
				"link.key" => "example.en",
				"link.href" => "/target",
				"link.locale" => "en",
			},
		]]
	ensure
		response&.close
		middleware.close
	end
end
