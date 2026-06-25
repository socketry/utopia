# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2014-2025, by Samuel Williams.
# Copyright, 2019, by Huba Nagy.

require "utopia/session"
require_relative "protocol_application"

describe Utopia::Session do
	include ProtocolApplication
	
	let(:app) do
		Utopia::Application.build(lambda{|request|
			case request.path_info
			when "/login"
				Utopia::Session["login"] = "true"
				
				Utopia::Response[200, {}, []]
			when "/session-set"
				Utopia::Session[request.arguments["key"].to_sym] = request.arguments["value"]
				
				Utopia::Response[200, {}, []]
			when "/session-get"
				Utopia::Response[200, {}, [Utopia::Session[request.arguments["key"].to_sym]]]
			else
				Utopia::Response[404, {}, []]
			end
		}) do
			use Utopia::Session,
				secret: "97111cabf4c1a5e85b8029cf7c61aa44424fc24a",
				expires_after: 5,
				update_timeout: 1
		end
	end
	
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
		expect(last_response.headers).to have_keys("set-cookie")
		
		get "/session-get?key=foo"
		expect(cookies).to be(:include?, "utopia.session.encrypted")
		expect(body).to be == "bar"
	end
	
	it "should ignore session if cookie value is invalid" do
		set_cookie "utopia.session.encrypted=junk"
		
		get "/session-get?key=foo"
		
		expect(body).to be == nil
	end
	
	it "shouldn't update the session if there are no changes" do
		get "/session-set?key=foo&value=bar"
		expect(last_response.headers).to have_keys("set-cookie")
		
		get "/session-set?key=foo&value=bar"
		expect(last_response.headers).not.to have_keys("set-cookie")
	end
	
	it "should update the session if time has passed" do
		get "/session-set?key=foo&value=bar"
		expect(last_response.headers).to have_keys("set-cookie")
		
		# Sleep more than update_timeout
		sleep 2
		
		get "/session-set?key=foo&value=bar"
		expect(last_response.headers).to have_keys("set-cookie")
	end
end

describe Utopia::Session do
	include ProtocolApplication
	
	let(:app) do
		Utopia::Application.build(lambda{|request|
			case request.path_info
			when "/session-set"
				Utopia::Session[request.arguments["key"].to_sym] = request.arguments["value"]
				
				Utopia::Response[200, {}, []]
			when "/session-get"
				Utopia::Response[200, {}, [Utopia::Session[request.arguments["key"].to_sym]]]
			else
				Utopia::Response[404, {}, []]
			end
		}) do
			use Utopia::Session,
				secret: "97111cabf4c1a5e85b8029cf7c61aa44424fc24a",
				expires_after: 5,
				update_timeout: 1
		end
	end
	
	def before
		# Initial user agent:
		header "User-Agent", "A"
		
		get "/session-set?key=foo&value=bar"
		
		super
	end
	
	it "should be able to retrive the value if there are no changes" do
		get "/session-get?key=foo"
		expect(body).to be == "bar"
	end
	
	it "should fail if user agent is changed" do
		# Change user agent:
		header "User-Agent", "B"
		
		get "/session-get?key=foo"
		expect(body).to be == nil
	end
	
	it "should fail if expired cookie is sent with the request" do
		session_cookie = last_response.headers["set-cookie"].first.split(";")[0]
		sleep 6 # sleep longer than the session timeout
		set_cookie session_cookie
		
		get "/session-get?key=foo"
		expect(body).to be == nil
	end
	
	it "shouldn't fail if ip address is changed" do
		# Change user agent:
		header "X-Forwarded-For", "127.0.0.10"
		
		get "/session-get?key=foo"
		expect(body).to be == "bar"
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
	
	it "does not allow mutation from another fiber" do
		hash = Utopia::Session::LazyHash.new do
			{}
		end
		
		fiber = Fiber.new do
			hash[:a] = 1
		end
		
		expect do
			fiber.resume
		end.to raise_exception(Utopia::Session::LazyHash::WrongFiberError)
	end
	
	it "does not allow mutation after commit" do
		hash = Utopia::Session::LazyHash.new do
			{}
		end
		
		hash.commit!
		
		expect do
			hash[:a] = 1
		end.to raise_exception(Utopia::Session::LazyHash::AlreadyCommittedError)
	end
end
