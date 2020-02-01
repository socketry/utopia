# frozen_string_literal: true

prepend Respond, Actions
respond.with_json

on 'fetch' do
	succeed! content: [1, 2, 3]
end
