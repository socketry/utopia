# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2015-2023, by Samuel Williams.

prepend Actions

class TharSheBlows < StandardError
end

on 'blow' do
	raise TharSheBlows.new("Arrrh!")
end

# The ExceptionHandler middleware will redirect here when an exception occurs. If this also fails, things get ugly.
on 'exception' do |request|
	if request.query_arguments["fatal"]
		raise TharSheBlows.new("Yarrh!")
	else
		respond! Utopia::Response[200, {"content-type" => "text/plain"}, ["Error: #{request.exception.message}"]]
	end
end
