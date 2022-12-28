# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2016-2020, by Samuel Williams.

prepend Respond, Actions
respond.with_json

class VersionedResponse
	def to_json(options = {})
		JSON.dump(self.as_json(options))
	end
	
	# Modelled after http://api.rubyonrails.org/classes/ActiveModel/Serializers/JSON.html
	def as_json(options = {})
		if options[:version] == '1'
			{"message" => "Hello World"}
		elsif options[:version] == '2'
			{"message" => "Goodbye World"}
		else
			{}
		end
	end
end

# To get different verions of the response, use:
# Accept: application/json;version=1
# Accept: application/json;version=2
on 'fetch' do
	succeed! content: VersionedResponse.new
end
