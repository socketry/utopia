# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2026, by Samuel Williams.

require "protocol/http/request"
require "tmpdir"

require "falcon/server"

require "utopia/application"
require "utopia/redirection"
require "utopia/session"
require "utopia/static"

describe "Utopia application middleware" do
	def request(path, headers: nil)
		Protocol::HTTP::Request["GET", path, headers]
	end
	
	it "passes request proxies through first-party middleware" do
		seen_request = nil
		
		application = Utopia::Application.build do
			use Utopia::Redirection::Rewrite, {"/old" => "/new"}
			
			run lambda{|request|
				seen_request = request
				Utopia::Response.text(request.path_info)
			}
		end
		
		response = application.call(request("/hello"))
		
		expect(seen_request).to be_a(Utopia::Request)
		expect(seen_request).to be(:respond_to?, :headers)
		expect(response.status).to be == 200
		expect(response.read).to be == "/hello"
		
		response = application.call(request("/old"))
		
		expect(response.status).to be == 301
		expect(response.headers["location"]).to be == "/new"
	end
	
	it "runs behind Falcon protocol middleware" do
		seen_request = nil
		application = Protocol::HTTP::Middleware.for do |request|
			seen_request = request
			Utopia::Response.text("Hello")
		end
		
		utopia_application = Utopia::Application.build(application)
		
		middleware = Falcon::Server.protocol_middleware(utopia_application, cache: false)
		response = middleware.call(request("/hello"))
		
		expect(seen_request).to be_a(Utopia::Request)
		expect(response.status).to be == 200
		expect(response.read).to be == "Hello"
	ensure
		response&.close
		middleware&.close
	end
	
	it "closes first-party middleware stacks" do
		closed = 0
		application = lambda{|request| Utopia::Response.text("OK")}
		application.define_singleton_method(:close) do
			closed += 1
		end
		
		utopia_application = Utopia::Application.build do
			use Utopia::Redirection::Rewrite, {"/old" => "/new"}
			use Utopia::Static
			run application
		end
		
		utopia_application.close
		
		expect(closed).to be == 1
	end
	
	it "serves static files from protocol requests" do
		Dir.mktmpdir do |directory|
			File.write(File.join(directory, "hello.txt"), "Hello")
			
			application = Utopia::Application.build do
				use Utopia::Static, root: directory
			end
			
			response = application.call(request("/hello.txt"))
			
			expect(response.status).to be == 200
			expect(response.headers["content-type"]).to be == "text/plain"
			expect(response.read).to be == "Hello"
		end
	end
	
	it "provides request-local session state" do
		application = Utopia::Application.build do
			use Utopia::Session, session_name: Utopia::Session::Middleware::SESSION_KEY, secret: "test-secret"
			
			run lambda{|request|
				request.session[:value] = "Hello"
				Utopia::Response.text("OK")
			}
		end
		
		response = application.call(request("/", headers: {"user-agent" => "Sus"}))
		
		expect(response.status).to be == 200
		expect(response.headers["set-cookie"].any?{|value| value.start_with?("utopia.session.encrypted=")}).to be == true
	end
end
