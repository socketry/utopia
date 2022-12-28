# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2016-2022, by Samuel Williams.

require_relative 'rack_helper'
require 'utopia/redirection'

RSpec.describe Utopia::Redirection do
	include_context "rack app", "redirection_spec.ru"
	
	it "should redirect directory to index" do
		get "/welcome/"
		
		expect(last_response.status).to be == 307
		expect(last_response.headers['location']).to be == '/welcome/index'
		expect(last_response.headers['cache-control']).to include("max-age=86400")
	end
	
	it "should be permanently moved" do
		get "/a"
		
		expect(last_response.status).to be == 301
		expect(last_response.headers['location']).to be == '/b'
		expect(last_response.headers['cache-control']).to include("max-age=86400")
	end
	
	it "should be permanently moved" do
		get "/"
		
		expect(last_response.status).to be == 301
		expect(last_response.headers['location']).to be == '/welcome/index'
		expect(last_response.headers['cache-control']).to include("max-age=86400")
	end
	
	it "should redirect on 404" do
		get "/foo"
		
		expect(last_response.status).to be == 404
		expect(last_response.body).to be == "File not found :("
	end
	
	it "should blow up if internal error redirect also fails" do
		expect{get "/teapot"}.to raise_error Utopia::Redirection::RequestFailure
	end
	
	it "should redirect deep url to top" do
		get "/hierarchy/a/b/c/d/e"
		
		expect(last_response.status).to be == 301
		expect(last_response.headers['location']).to be == '/hierarchy'
	end
	
	it "should get a weird status" do
		get "/weird"
		
		expect(last_response.status).to be == 333
		expect(last_response.headers['location']).to be == '/status'
	end
end
