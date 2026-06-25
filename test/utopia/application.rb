# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2026, by Samuel Williams.

require "protocol/http/request"
require "tmpdir"
require "utopia/application"

describe Utopia::Application do
	let(:http_request) {Protocol::HTTP::Request["GET", "/hello?name=sam"]}
	
	it "passes protocol requests through the application stack" do
		application_request = nil
		
		application = subject.build do
			run lambda{|request|
				application_request = request
				
				Utopia::Response.text("Hello")
			}
		end
		
		response = application.call(http_request)
		
		expect(application_request).to be_equal(http_request)
		
		expect(response).to be_a(Protocol::HTTP::Response)
		expect(response.status).to be == 200
		expect(response.headers["content-type"]).to be == "text/plain; charset=utf-8"
	end
	
	it "installs ambient Utopia request state" do
		utopia_request = nil
		previous_request = Object.new
		
		application = subject.build do
			run lambda{|request|
				utopia_request = Utopia::Request.current
				
				Utopia::Response.text(utopia_request.path_info)
			}
		end
		
		Utopia::Request.current = previous_request
		
		begin
			response = application.call(http_request)
			
			expect(utopia_request).to be_a(Utopia::Request)
			expect(utopia_request.http).to be_equal(http_request)
			expect(utopia_request.query).to be == "name=sam"
			expect(response.read).to be == "/hello"
			expect(Utopia::Request.current).to be_equal(previous_request)
		ensure
			Utopia::Request.current = nil
		end
	end
	
	it "normalizes protocol response objects" do
		response_object = Object.new
		
		def response_object.to_protocol_response
			Utopia::Response.text("Created", 201)
		end
		
		application = subject.build do
			run lambda{|request| response_object}
		end
		
		response = application.call(http_request)
		
		expect(response).to be_a(Protocol::HTTP::Response)
		expect(response.status).to be == 201
		expect(response.read).to be == "Created"
	end
	
	it "uses a not found default" do
		application = subject.default
		
		response = application.call(http_request)
		
		expect(response).to be_a(Protocol::HTTP::Response)
		expect(response.status).to be == 404
	end
	
	it "loads a top-level application constant" do
		Dir.mktmpdir do |directory|
			path = File.join(directory, "application.rb")
			
			File.write(path, <<~RUBY)
				require "utopia/application"
				
				Application = Utopia::Application.build do
					run lambda{|request| Utopia::Response.text(Utopia::Request.current.path_info)}
				end
			RUBY
			
			application = subject.load(path)
			response = application.call(http_request)
			
			expect(response.status).to be == 200
			expect(response.read).to be == "/hello"
			expect(Object.const_defined?(:Application, false)).to be == false
		end
	end
	
	it "uses the default application if no application constant is defined" do
		Dir.mktmpdir do |directory|
			path = File.join(directory, "application.rb")
			
			File.write(path, <<~RUBY)
				require "utopia/application"
			RUBY
			
			application = subject.load(path)
			response = application.call(http_request)
			
			expect(response.status).to be == 404
		end
	end
end
