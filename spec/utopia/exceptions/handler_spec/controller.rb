
prepend Actions

class TharSheBlows < StandardError
end

on 'blow' do
	raise TharSheBlows.new("Arrrh!")
end

# The ExceptionHandler middleware will redirect here when an exception occurs. If this also fails, things get ugly.
on 'exception' do |request|
	if request['fatal']
		raise TharSheBlows.new("Yarrh!")
	else
		succeed! :content => 'Error Will Robertson', :type => 'text/plain'
	end
end
