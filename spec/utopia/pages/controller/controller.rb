
on 'flat' do
	success! content: "flat"
end

on '**/hello-world' do
	success! content: @hello_world
end

on '**' do
	@hello_world = "Hello World"
end