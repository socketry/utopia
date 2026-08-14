# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2014-2025, by Samuel Williams.
# Copyright, 2019, by Huba Nagy.

require "sus/fixtures/protocol/http/middleware_context"
require "utopia/application"
require "utopia/session"

describe Utopia::Session do
	include Sus::Fixtures::Protocol::HTTP::MiddlewareContext
	
	let(:middleware) do
		Utopia::Application.build(Protocol::HTTP::Middleware.for{|request|
			case request.path.to_s
			when "/login"
				request.session["login"] = "true"
				
				Utopia::Response[200, {}, []]
			when "/session-set"
				request.session[request.query_parameters["key"].to_sym] = request.query_parameters["value"]
				
				Utopia::Response[200, {}, []]
			when "/session-get"
				Utopia::Response[200, {}, [request.session[request.query_parameters["key"].to_sym]]]
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
		client.get "/"
		expect(last_response.headers).not.to have_keys("set-cookie")
		
		# This URL updates the session:
		client.get "/login"
		expect(last_response.headers).to have_keys("set-cookie")
	end
	
	it "should set and get values correctly" do
		client.get "/session-set?key=foo&value=bar"
		expect(last_response.headers).to have_keys("set-cookie")
		expect(last_response.headers["set-cookie"].first).not.to be(:include?, "%")
		
		client.get "/session-get?key=foo"
		expect(client.cookies).to be(:include?, "utopia.session.encrypted")
		expect(last_response.read).to be == "bar"
	end
	
	it "should ignore session if cookie value is invalid" do
		client.set_cookie "utopia.session.encrypted=junk"
		
		client.get "/session-get?key=foo"
		
		expect(last_response.read).to be == nil
	end
	
	it "shouldn't update the session if there are no changes" do
		client.get "/session-set?key=foo&value=bar"
		expect(last_response.headers).to have_keys("set-cookie")
		
		client.get "/session-set?key=foo&value=bar"
		expect(last_response.headers).not.to have_keys("set-cookie")
	end
	
	it "should update the session if time has passed" do
		client.get "/session-set?key=foo&value=bar"
		expect(last_response.headers).to have_keys("set-cookie")
		
		# Sleep more than update_timeout
		sleep 2
		
		client.get "/session-set?key=foo&value=bar"
		expect(last_response.headers).to have_keys("set-cookie")
	end
	
end

describe Utopia::Session::Middleware do
	let(:delegate) do
		Protocol::HTTP::Middleware.for do |request|
			request.session[:updated] = true
			
			Utopia::Response[200, {}, []]
		end
	end
	
	def middleware(**options)
		return subject.new(delegate, secret: "test-secret", **options)
	end
	
	it "emits the default cookie directives" do
		response = middleware.call(Utopia::Request["GET", "/"])
		cookie = response.headers["set-cookie"].first
		
		expect(cookie).to be(:include?, ";Path=/")
		expect(cookie).to be(:include?, ";Expires=")
		expect(cookie).to be(:include?, ";HttpOnly")
		expect(cookie).to be(:include?, ";SameSite=Lax")
	end
	
	it "emits the supported cookie directives" do
		instance = middleware(
			domain: "example.com",
			path: "/session",
			max_age: 60,
			secure: true,
			http_only: false,
			same_site: :none,
			partitioned: true,
		)
		
		response = instance.call(Utopia::Request["GET", "/"])
		cookie = response.headers["set-cookie"].first
		
		expect(cookie).to be(:include?, ";Domain=example.com")
		expect(cookie).to be(:include?, ";Path=/session")
		expect(cookie).to be(:include?, ";Max-Age=60")
		expect(cookie).to be(:include?, ";Secure")
		expect(cookie).not.to be(:include?, ";HttpOnly")
		expect(cookie).to be(:include?, ";SameSite=None")
		expect(cookie).to be(:include?, ";Partitioned")
	end
	
	it "normalizes SameSite options" do
		{
			false => nil,
			nil => nil,
			true => "Strict",
			strict: "Strict",
			lax: "Lax",
			none: "None",
		}.each do |option, expected|
			expect(middleware(same_site: option).cookie_defaults[:same_site]).to be == expected
		end
	end
	
	it "rejects invalid SameSite values" do
		expect do
			middleware(same_site: :invalid)
		end.to raise_exception(ArgumentError)
	end
	
	it "rejects unknown cookie options" do
		expect do
			middleware(unknown: true)
		end.to raise_exception(ArgumentError)
	end
end

describe Utopia::Session do
	include Sus::Fixtures::Protocol::HTTP::MiddlewareContext
	
	let(:middleware) do
		Utopia::Application.build(Protocol::HTTP::Middleware.for{|request|
			case request.path.to_s
			when "/session-set"
				request.session[request.query_parameters["key"].to_sym] = request.query_parameters["value"]
				
				Utopia::Response[200, {}, []]
			when "/session-get"
				Utopia::Response[200, {}, [request.session[request.query_parameters["key"].to_sym]]]
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
		client.headers["user-agent"] = "A"
		
		client.get "/session-set?key=foo&value=bar"
		
		super
	end
	
	it "should be able to retrive the value if there are no changes" do
		client.get "/session-get?key=foo"
		expect(last_response.read).to be == "bar"
	end
	
	it "should fail if user agent is changed" do
		# Change user agent:
		client.headers["user-agent"] = "B"
		
		client.get "/session-get?key=foo"
		expect(last_response.read).to be == nil
	end
	
	it "should fail if expired cookie is sent with the request" do
		session_cookie = last_response.headers["set-cookie"].first.split(";")[0]
		sleep 6 # sleep longer than the session timeout
		client.set_cookie session_cookie
		
		client.get "/session-get?key=foo"
		expect(last_response.read).to be == nil
	end
	
	it "shouldn't fail if ip address is changed" do
		# Change user agent:
		client.headers["x-forwarded-for"] = "127.0.0.10"
		
		client.get "/session-get?key=foo"
		expect(last_response.read).to be == "bar"
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
