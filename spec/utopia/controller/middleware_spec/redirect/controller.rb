# frozen_string_literal: true

prepend Actions

on '**' do |request, path|
	# puts "**: #{URI_PATH.inspect}"
	
	if path.include? 'foo'
		# This should ALWAYS give /redirect
		succeed! content: URI_PATH.to_s
	end
end
