# frozen_string_literal: true

use Utopia::Session,
	secret: "97111cabf4c1a5e85b8029cf7c61aa44424fc24a",
	expires_after: 5,
	update_timeout: 1

run lambda { |env|
	request = Rack::Request.new(env)
	
	if env[Rack::PATH_INFO] =~ /login/
		env["rack.session"]["login"] = "true"
		
		[200, {}, []]
	elsif env[Rack::PATH_INFO] =~ /session-set/
		env["rack.session"][request.params["key"].to_sym] = request.params["value"]
		
		[200, {}, []]
	elsif env[Rack::PATH_INFO] =~ /session-get/
		[200, {}, [env["rack.session"][request.params["key"].to_sym]]]
	else
		[404, {}, []]
	end
}
