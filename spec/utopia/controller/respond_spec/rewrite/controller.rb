# frozen_string_literal: true

prepend Respond, Rewrite, Actions

respond.with_json

rewrite.extract_prefix id: Integer do |request|
	fail! :not_found, message: "Could not find record" if @id == 1
end

on 'show' do
	succeed! content: {id: @id, foo: 'bar'}
end
