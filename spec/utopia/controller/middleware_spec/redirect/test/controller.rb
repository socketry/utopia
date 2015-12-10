
on 'bar' do |request, path|
	puts "bar: #{URI_PATH.inspect}"
	
	succeed!
end
