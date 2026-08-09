# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2015-2023, by Samuel Williams.

prepend Actions

on "all_locales" do |request, path|
	succeed! content: request.localization.all_locales.join(",")
end

on "default_locale" do |request, path|
	succeed! content: request.localization.default_locale
end

on "locale" do |request, path|
	succeed! content: request.localization.locale
end
