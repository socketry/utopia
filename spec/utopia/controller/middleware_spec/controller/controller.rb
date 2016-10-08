
on 'flat' do
	succeed! content: "flat"
end

on '**/hello-world' do
	succeed! content: @hello_world
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

on 'index' do
	succeed! content: 'Hello World'
end
