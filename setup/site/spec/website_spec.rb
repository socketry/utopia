
require_relative 'website_context'

# Learn about best practice specs from http://betterspecs.org
RSpec.describe "my website" do
	include_context "website"
	
	it "should have an accessible front page" do
		get "/"
		
		follow_redirect!
		
		expect(last_response.status).to be == 200
	end
end
