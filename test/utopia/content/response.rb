# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2012-2023, by Samuel Williams.

require 'utopia/content/response'

describe Utopia::Content::Response do
	let(:response) {subject.new}
	
	it "should specify not to cache content" do
		response.cache!(1000)
		response.do_not_cache!
		
		expect(response.headers['cache-control']).to be == "no-cache, must-revalidate"
		
		expires_header = Time.parse(response.headers['expires'])
		expect(expires_header).to be <= Time.now
	end
	
	it "should specify to cache content" do
		duration = 120
		expires = Time.now + 100 # At least this far into the future
		response.cache!(duration)
		
		expect(response.headers['cache-control']).to be == "public, max-age=120"
		
		expires_header = Time.parse(response.headers['expires'])
		expect(expires_header).to be >= expires
	end
	
	it "should set content type" do
		response.content_type! "text/html"
		
		expect(response.headers['content-type']).to be == "text/html"
	end
end
