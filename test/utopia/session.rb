# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2014-2025, by Samuel Williams.
# Copyright, 2019, by Huba Nagy.

require "rack"
require "rack/test"

require "utopia/session"

describe Utopia::Session do
	include Rack::Test::Methods
	
	let(:app) {Rack::Builder.parse_file(File.expand_path("session_spec.ru", __dir__))}
	
	it "shouldn't commit session values unless required" do
		# This URL doesn't update the session:
		get "/"
		expect(last_response.headers).not.to have_keys("set-cookie")
		
		# This URL updates the session:
		get "/login"
		expect(last_response.headers).to have_keys("set-cookie")
	end
	
	it "should set and get values correctly" do
		get "/session-set?key=foo&value=bar"
		expect(last_response.headers).to be(:include?, "Set-Cookie")
		
		get "/session-get?key=foo"
		expect(last_request.cookies).to be(:include?, "rack.session.encrypted")
		expect(last_response.body).to be == "bar"
	end
	
	it "should ignore session if cookie value is invalid" do
		set_cookie "rack.session.encrypted=junk"
		
		get "/session-get?key=foo"
		
		expect(last_response.body).to be == ""
	end
	
	it "shouldn't update the session if there are no changes" do
		get "/session-set?key=foo&value=bar"
		expect(last_response.headers).to be(:include?, "Set-Cookie")
		
		get "/session-set?key=foo&value=bar"
		expect(last_response.headers).not.to be(:include?, "Set-Cookie")
	end
	
	it "should update the session if time has passed" do
		get "/session-set?key=foo&value=bar"
		expect(last_response.headers).to be(:include?, "Set-Cookie")
		
		# Sleep more than update_timeout
		sleep 2
		
		get "/session-set?key=foo&value=bar"
		expect(last_response.headers).to be(:include?, "Set-Cookie")
	end
end

describe Utopia::Session do
	include Rack::Test::Methods
	
	let(:app) {Rack::Builder.parse_file(File.expand_path("session_spec.ru", __dir__))}
	
	def before
		# Initial user agent:
		header "User-Agent", "A"
		
		get "/session-set?key=foo&value=bar"
		
		super
	end
	
	it "should be able to retrive the value if there are no changes" do
		get "/session-get?key=foo"
		expect(last_response.body).to be == "bar"
	end
	
	it "should fail if user agent is changed" do
		# Change user agent:
		header "User-Agent", "B"
		
		get "/session-get?key=foo"
		expect(last_response.body).to be == ""
	end
	
	it "should fail if expired cookie is sent with the request" do
		session_cookie = last_response["Set-Cookie"].split(";")[0]
		sleep 6 # sleep longer than the session timeout
		header "Cookie", session_cookie
		
		get "/session-get?key=foo"
		expect(last_response.body).to be == ""
	end
	
	it "shouldn't fail if ip address is changed" do
		# Change user agent:
		header "X-Forwarded-For", "127.0.0.10"
		
		get "/session-get?key=foo"
		expect(last_response.body).to be == "bar"
	end
end

describe Utopia::Session::LazyHash do
	it "should load hash only when required" do
		loaded = false
		
		hash = Utopia::Session::LazyHash.new do
			loaded = true
			{a: 10, b: 20}
		end
		
		expect(loaded).to be == false
		
		expect(hash[:a]).to be == 10
		
		expect(loaded).to be == true
	end
	
	it "should need to be reloaded if changed" do
		hash = Utopia::Session::LazyHash.new do
			{a: 10}
		end
		
		expect(hash.needs_update?).to be == false
		
		hash[:a] = 10
		
		expect(hash.needs_update?).to be == false
		
		hash[:a] = 20
		
		expect(hash.needs_update?).to be == true
	end
	
	it "should need to be reloaded if old" do
		hash = Utopia::Session::LazyHash.new do
			{updated_at: Time.now - 3700}
		end
		
		expect(hash.needs_update?(3600)).to be == false
		
		expect(hash).to be(:include?, :updated_at)
		
		# If the timeout is 2 hours, it shouldn't require any update:
		expect(hash.needs_update?(3600*2)).to be == false
		
		# However if the timeout is 1 hour ago, it WILL require an update:
		expect(hash.needs_update?(3600)).to be == true
	end
	
	it "should delete the specified item" do
		hash = Utopia::Session::LazyHash.new do
			{a: 10, b: 20}
		end
		
		expect(hash).to be(:include?, :a)
		expect(hash).to be(:include?, :b)
		
		expect(hash.delete(:a)).to be == 10
		
		expect(hash).to be(:include?, :b)
		expect(hash).not.to be(:include?, :a)
		
		expect(hash).to be(:needs_update?)
	end
end
