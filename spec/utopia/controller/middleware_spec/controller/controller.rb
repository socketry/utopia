
prepend Actions

on 'flat' do
	succeed! content: "flat"
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
