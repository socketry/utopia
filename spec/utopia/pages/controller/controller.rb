
on 'flat' do
	success! content: "flat"
end

on '**/hello-world' do
	success! content: @hello_world
end

on '**' do
	@hello_world = "Hello World"
end

on 'ignore' do
	ignore!
end

on 'redirect' do
	redirect! 'bar'
end

on 'rewrite' do
	rewrite! 'index'
end

on 'index' do
	success! content: 'Hello World'
end

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