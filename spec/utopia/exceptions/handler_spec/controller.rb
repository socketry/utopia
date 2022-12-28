# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2015-2020, by Samuel Williams.

prepend Actions

class TharSheBlows < StandardError
end

on 'blow' do
	raise TharSheBlows.new("Arrrh!")
end

# The ExceptionHandler middleware will redirect here when an exception occurs. If this also fails, things get ugly.
on 'exception' do |request|
	if request.params['fatal']
		raise TharSheBlows.new("Yarrh!")
	else
		succeed! :content => 'Error Will Robertson', :type => 'text/plain'
	end
end
