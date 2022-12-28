# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2012-2022, by Samuel Williams.

require 'utopia/content/response'

module Utopia::Content::ResponseSpec
	describe Utopia::Content::Response do
		it "should specify not to cache content" do
			subject.cache!(1000)
			subject.do_not_cache!
			
			expect(subject.headers['cache-control']).to be == "no-cache, must-revalidate"
			
			expires_header = Time.parse(subject.headers['expires'])
			expect(expires_header).to be <= Time.now
		end
		
		it "should specify to cache content" do
			duration = 120
			expires = Time.now + 100 # At least this far into the future
			subject.cache!(duration)
			
			expect(subject.headers['cache-control']).to be == "public, max-age=120"
			
			expires_header = Time.parse(subject.headers['expires'])
			expect(expires_header).to be >= expires
		end
		
		it "should set content type" do
			subject.content_type! "text/html"
			
			expect(subject.headers['content-type']).to be == "text/html"
		end
	end
end
