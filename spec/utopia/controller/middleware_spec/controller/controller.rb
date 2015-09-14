
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

on 'index' do
	success! content: 'Hello World'
end
