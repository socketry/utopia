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
		
		expect(application_request).to be_a(Utopia::Request)
		expect(application_request.http).to be_equal(http_request)
		expect(application_request.path_info).to be == "/hello"
		expect(application_request.query).to be == "name=sam"
		
		expect(response).to be_a(Protocol::HTTP::Response)
		expect(response.status).to be == 200
		expect(response.headers["content-type"]).to be == "text/plain; charset=utf-8"
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
					run lambda{|request| Utopia::Response.text(request.path_info)}
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
