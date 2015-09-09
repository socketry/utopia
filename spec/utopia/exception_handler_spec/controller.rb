
class TharSheBlows < StandardError
end

on 'blow' do
	raise TharSheBlows.new("Arrrh!")
end

on 'exception' do |request|
	if request['fatal']
		raise TharSheBlows.new("Yarrh!")
	else
		success! :content => 'Error Will Robertson', :type => 'text/plain'
	end
end
