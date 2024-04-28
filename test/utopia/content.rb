# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2012-2023, by Samuel Williams.

require 'rack/test'
require 'utopia/content'

describe Utopia::Content do
	include Rack::Test::Methods
	
	let(:app) {Rack::Builder.parse_file(File.expand_path('content.ru', __dir__))}
	
	it "should generate identical html" do
		get "/test"
		
		expect(last_response.body).to be == File.read(File.expand_path('.content/test.xnode', __dir__))
	end
	
	it "should get a local path" do
		get '/node/index'
		
		expect(last_response.body).to be == File.expand_path('.content/node', __dir__)
	end
	
	it "should successfully redirect to the index page" do
		get '/'
		
		expect(last_response.status).to be == 307
		expect(last_response.headers['location']).to be == '/index'
		
		get '/content'
		
		expect(last_response.status).to be == 307
		expect(last_response.headers['location']).to be == '/content/index'
	end
	
	it "should successfully render the index page" do
		get "/index"
		
		expect(last_response.body).to be == '<h1>Hello World</h1>'
	end
	
	it "should render partials correctly" do
		get "/content/test-partial"
		
		expect(last_response.body).to be == '10'
	end
	
	it "should successfully redirect to the foo page" do
		get '/content/redirect'
		
		expect(last_response.status).to be == 307
		expect(last_response.headers['location']).to be == 'foo'
	end
end

describe Utopia::Content do
	let(:root) {File.expand_path('.content', __dir__)}
	let(:content) {Utopia::Content.new(lambda{}, root: root)}
	
	it "should parse file and expand variables" do
		path = Utopia::Path.create('/index')
		node = content.lookup_node(path)
		expect(node).to be_a Utopia::Content::Node
	
		status, headers, body = node.process!({}, {})
		expect(body.join).to be == '<h1>Hello World</h1>'
	end
	
	it "should fetch template and use cache" do
		node_path = File.expand_path('.content/index.xnode', __dir__)
		
		template = content.fetch_template(node_path)
		
		expect(template).to be_a XRB::Template
		
		# Check that the same object is returned:
		expect(template).to be == content.fetch_template(node_path)
	end
end
