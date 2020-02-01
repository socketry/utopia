# frozen_string_literal: true

prepend Actions

on 'foobar' do
	succeed! content: "Foobar"
end