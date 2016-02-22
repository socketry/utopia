
use Utopia::Redirector,
	patterns: [
		Utopia::Redirector::DIRECTORY_INDEX,
		[:moved, "/a", "/b"],
	],
	strings: {
		'/' => '/c',
	},
	errors: {
		404 => "/error",
		418 => "/teapot",
	}

def error_handler(env)
	request = Rack::Request.new(env)
	if request.path_info == "/error"
		[200, {}, ["File not found :("]]
	elsif request.path_info == "/teapot"
		[418, {}, ["I'm a teapot!"]]
	else
		[404, {}, []]
	end
end

run self.method(:error_handler)
