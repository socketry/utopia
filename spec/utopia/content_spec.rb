# Copyright, 2012, by Samuel G. D. Williams. <http://www.codeotaku.com>
# 
# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:
# 
# The above copyright notice and this permission notice shall be included in
# all copies or substantial portions of the Software.
# 
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
# THE SOFTWARE.

require 'rack/test'
require 'utopia/content'

module Utopia::ContentSpec
	describe Utopia::Content do
		include Rack::Test::Methods
		
		let(:app) {Rack::Builder.parse_file(File.expand_path('content_spec.ru', __dir__)).first}
		
		it "should generate identical html" do
			get "/test"
			
			expect(last_response.body).to be == File.read(File.expand_path('content_spec/test.xnode', __dir__))
		end
		
		it "should get a local path" do
			get '/node/index'
			
			expect(last_response.body).to be == File.expand_path('content_spec/node', __dir__)
		end
		
		it "should successfully redirect to the index page" do
			get '/'
			
			expect(last_response.status).to be == 307
			expect(last_response.headers['Location']).to be == '/index'
			
			get '/content'
			
			expect(last_response.status).to be == 307
			expect(last_response.headers['Location']).to be == '/content/index'
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
			expect(last_response.headers['Location']).to be == 'foo'
		end
	end
	
	describe Utopia::Content do
		let(:root) {File.expand_path('content_spec', __dir__)}
		let(:content) {Utopia::Content.new(lambda{}, root: root, cache_templates: true)}
		
		it "should parse file and expand variables" do
			path = Utopia::Path.create('/index')
			node = content.lookup_node(path)
			expect(node).to be_kind_of Utopia::Content::Node
		
			status, headers, body = node.process!({}, {})
			expect(body.join).to be == '<h1>Hello World</h1>'
		end
		
		it "should fetch template and use cache" do
			node_path = File.expand_path('../content_spec/index.xnode', __FILE__)
			
			template = content.fetch_template(node_path)
			
			expect(template).to be_kind_of Trenni::Template
			
			# Check that the same object is returned:
			expect(template).to be content.fetch_template(node_path)
		end
	end
end
