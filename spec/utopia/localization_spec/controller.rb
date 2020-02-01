# frozen_string_literal: true

prepend Actions

on 'all_locales' do |request, path|
	wrapper = Utopia::Localization[request]
	
	succeed! content: wrapper.all_locales.join(',')
end

on 'default_locale' do |request, path|
	wrapper = Utopia::Localization[request]
	
	succeed! content: wrapper.default_locale
end

on 'current_locale' do |request, path|
	wrapper = Utopia::Localization[request]
	
	succeed! content: wrapper.current_locale
end
