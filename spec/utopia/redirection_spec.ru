
use Utopia::Redirection::Rewrite, "/" => "/welcome/index"

use Utopia::Redirection::DirectoryIndex

use Utopia::Redirection::Errors,
	404 => '/error',
	418 => '/teapot'

use Utopia::Redirection::Moved, "/a", "/b"
use Utopia::Redirection::Moved, "/hierarchy/", "/hierarchy", flatten: true
use Utopia::Redirection::Moved, "/weird", "/status", status: 333

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
