
use Utopia::Session::EncryptedCookie, secret: "97111cabf4c1a5e85b8029cf7c61aa44424fc24a"

run lambda {|env|
	if env['PATH_INFO'] =~ /login/
		env['rack.session']['login'] = 'true'
		
		[200, {}, []]
	else
		[404, {}, []]
	end
}
