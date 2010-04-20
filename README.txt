*** Utopia Website Framework ***

Utopia is a website generation framework which provides a robust set of tools to build highly complex dynamic websites. It uses the filesystem heavily for content and provides frameworks for interacting with files and directories as structure representing the website.

Utopia provides a number of middleware objects for providing advanced functionality:
	Utopia::Middleware::Static => Serve static files with recursive lookup
	Utopia::Middleware::Requester => Allow nesting of virtual requests
	Utopia::Middleware::Redirector => Redirect URL patterns and status codes
	Utopia::Middleware::Logger => Advanced rotating access log
	Utopia::Middleware::Localization => Non-intrusive localization of resources
	Utopia::Middleware::DirectoryIndex => Redirect directory requests to specific files
	Utopia::Middleware::Controller => Dynamic behaviour with recursive execution
	Utopia::Middleware::Content => XML-style template engine with powerful tag behaviours
	Utopia::Session::EncryptedCookie => Session storage using an encrypted cookie

*** Live Examples ***

The following sites all use the Utopia Website Framework:

	http://www.oriontransfer.co.nz/ (uses Localization middleware)
	http://www.drobo.co.nz/
	http://programming.dojo.net.nz/
