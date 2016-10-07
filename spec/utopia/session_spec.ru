
use Utopia::Session, secret: "97111cabf4c1a5e85b8029cf7c61aa44424fc24a"

run lambda { |env|
	request = Rack::Request.new(env)
	
	if env[Rack::PATH_INFO] =~ /login/
		env['rack.session']['login'] = 'true'
		
		[200, {}, []]
	elsif env[Rack::PATH_INFO] =~ /session-set/
		env['rack.session'][request[:key]] = request[:value]
		
		[200, {}, []]
	elsif env[Rack::PATH_INFO] =~ /session-get/
		[200, {}, [env['rack.session'][request[:key]]]]
	else
		[404, {}, []]
	end
}
