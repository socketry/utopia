# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2026, by Samuel Williams.

require "protocol/http/request"
require "tmpdir"
require "utopia/application"
require "variant"

describe Utopia::Application do
	let(:http_request) {Protocol::HTTP::Request["GET", "/hello?name=sam"]}
	
	it "passes request proxies through the application stack" do
		application_request = nil
		
		application = subject.build do
			run Protocol::HTTP::Middleware.for{|request|
				application_request = request
				
				Utopia::Response.text("Hello")
			}
		end
		
		response = application.call(http_request)
		
		expect(application_request).to be_a(Utopia::Request)
		expect(application_request.delegate).to be_equal(http_request)
		expect(application_request.path).to be == Utopia::Path["/hello"]
		expect(application_request.url.query).to be == "name=sam"
		
		expect(response).to be_a(Protocol::HTTP::Response)
		expect(response.status).to be == 200
		expect(response.headers["content-type"]).to be == "text/plain; charset=utf-8"
	end
	
	it "yields the builder to blocks accepting arguments" do
		application = subject.build do |builder|
			builder.run Protocol::HTTP::Middleware.for{|request| Utopia::Response.text("Hello")}
		end
		
		response = application.call(http_request)
		
		expect(response.status).to be == 200
		expect(response.read).to be == "Hello"
	end
	
	it "normalizes protocol response objects" do
		response_object = Object.new
		
		def response_object.to_response
			Utopia::Response.text("Created", 201)
		end
		
		application = subject.build do
			run Protocol::HTTP::Middleware.for{|request| response_object}
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
	
	it "rejects options for the default application" do
		expect do
			subject.default(unexpected: true)
		end.to raise_exception(ArgumentError)
	end
	
	it "loads a top-level application constant" do
		Dir.mktmpdir do |directory|
			path = File.join(directory, "application.rb")
			
			File.write(path, <<~RUBY)
				require "utopia/application"
				
				Application = Utopia::Application.build do
					run Protocol::HTTP::Middleware.for{|request| Utopia::Response.text(request.path.to_s)}
				end
			RUBY
			
			application = subject.load(path)
			response = application.call(http_request)
			
			expect(response.status).to be == 200
			expect(response.read).to be == "/hello"
			expect(Object.const_defined?(:Application, false)).to be == false
		end
	end
	
	it "passes options to application classes" do
		Dir.mktmpdir do |directory|
			path = File.join(directory, "application.rb")
			
			File.write(path, <<~RUBY)
				require "utopia/application"
				
				class Application < Utopia::Application
					def initialize(message:)
						delegate = Protocol::HTTP::Middleware.for do |request|
							Utopia::Response.text(message)
						end
						
						super(delegate)
					end
				end
			RUBY
			
			application = subject.load(path, message: "Hello")
			response = application.call(http_request)
			
			expect(response.status).to be == 200
			expect(response.read).to be == "Hello"
		end
	end
	
	it "uses the default application if the configuration file does not exist" do
		Dir.mktmpdir do |directory|
			path = File.join(directory, "missing.rb")
			application = subject.load(path, ignored: true)
			response = application.call(http_request)
			
			expect(response.status).to be == 404
		end
	end
	
	it "uses the default application if no application constant is defined" do
		Dir.mktmpdir do |directory|
			path = File.join(directory, "application.rb")
			
			File.write(path, <<~RUBY)
				require "utopia/application"
			RUBY
			
			application = subject.load(path, ignored: true)
			response = application.call(http_request)
			
			expect(response.status).to be == 404
		end
	end
	
	it "loads the generated production serve configuration" do
		path = File.expand_path("../../setup/site/config/serve.rb", __dir__)
		application = nil
		response = nil
		
		Variant::Environment.instance.with({"VARIANT" => "production"}) do
			application = Protocol::HTTP::Middleware.load(path)
			response = application.call(Protocol::HTTP::Request["GET", "/"])
			
			expect(application).to be_a(Utopia::Application)
			expect(response.status).to be == 301
			expect(response.headers["location"]).to be == "/welcome/index"
		end
	ensure
		response&.close
		application&.close
	end
end
