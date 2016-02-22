
use Utopia::Redirector,
	patterns: [
		Utopia::Redirector::DIRECTORY_INDEX,
		[:moved, "/a", "/b"],
	],
	strings: {
		'/' => '/c',
	},
	errors: {
		404 => "/error"
	}

def error_handler(env)
	request = Rack::Request.new(env)
	if request.path_info == "/error"
		[200, {}, ["File Not Found :("]]
	else
		[404, {}, []]
	end
end

run self.method(:error_handler)
