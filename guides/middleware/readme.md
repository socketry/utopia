# Middleware

This guide gives an overview of the different Rack middleware used by Utopia.

## Static

The {ruby Utopia::Static} middleware services static files efficiently. By default, it works with `Rack::Sendfile` and supports `ETag` based caching. Normally, you'd prefer to put static files into `public/_static` but it's also acceptable to put static content into `pages/` if it makes sense.

~~~ ruby
use Utopia::Static,
	# The root path to serve files from:
	root: "path/to/root",
	# The mime-types to recognize/serve:
	types: [:default, :xiph],
	# Cache-Control header for files:
	cache_control: 'public, max-age=7200'
~~~

## Redirection

The {ruby Utopia::Redirection} middleware is used for redirecting requests based on patterns and status codes.

~~~ ruby
# String (fast hash lookup) rewriting:
use Utopia::Redirection::Rewrite,
	'/' => '/welcome/index'

# Redirect directories (e.g. /) to an index file (e.g. /index):
use Utopia::Redirection::DirectoryIndex,
	index: 'index.html'

# Redirect (error) status codes to actual pages:
use Utopia::Redirection::Errors,
	404 => '/errors/file-not-found'
~~~

## Localization

The {ruby Utopia::Localization} middleware provides non-intrusive localization on top of the controller and view layers. The middleware uses the `accept-language` header to guess the preferred locale out of the given options. If a request path maps to a resource, that resource is returned. Otherwise, a non-localized request is made.

~~~ ruby
use Utopia::Localization,
	:default_locale => 'en',
	:locales => ['en', 'de', 'ja', 'zh']
~~~

To localize a specific `xnode`, append the locale as a postfix:

~~~
pages/index.xnode
pages/index.de.xnode
pages/index.ja.xnode
pages/index.zh.xnode
~~~

You can also access the current locale in the view via {ruby Utopia::Content::Node::Context#localization}.

## Controller

The {ruby Utopia::Controller} middleware provides flexible nested controllers with efficient behaviour. Controllers are nested in the `pages` directory and are matched against the incoming request path recursively, from outer most to inner most.

```ruby
use Utopia::Controller,
	# The root directory where `controller.rb` files can be found.
	root: 'path/to/root',
	# The base class to use for all controllers:
	base: Utopia::Controller::Base,
```

A controller is a file within the specified root directory (typically `pages`) with the name `controller.rb`. This code is dynamically loaded into an anonymous class and executed. The default controller has only a single function:

```ruby
def passthrough(request, path)
	# Call one of:
	
	# This will cause the middleware to generate a response.
	# def respond!(response)

	# This will cause the controller to skip the request.
	# def ignore!

	# Request relative redirect. Respond with a redirect to the given target.
	# def redirect! (target, status = 302)
	
	# Controller relative redirect.
	# def goto!(target, status = 302)
	
	# Respond with an error which indiciates some kind of failure.
	# def fail!(error = 400, message = nil)
	
	# Succeed the request and immediately respond.
	# def succeed!(status: 200, headers: {}, **options)
	# options may include content: string or body: Enumerable (as per Rack specifications
end
```

The controller layer can do more complex operations by prepending modules into it.

```ruby
prepend Rewrite, Actions

# Extracts an Integer
rewrite.extract_prefix id: Integer do
	@user = User.find_by_id(@id)
end

on 'edit' do |request, path|
	if request.post?
		@user.update_attributes(request[:user])
	end
end

otherwise do |request, path|
	# Executed if no specific named actions were executed.
	succeed!
end
```

The incoming path is relative to the path of the controller itself.

## Content

The {ruby Utopia::Content} middleware parses XML-style templates with using attributes provided by the controller layer. Dynamic tags can be used to build modular content.

~~~ ruby
use Utopia::Content
~~~

A basic template `create.xnode` looks something like:

~~~trenni
<content:page>
	<content:heading>Create User</content:heading>
	<form action="#">
		<input name="name" />
		<input type="submit" />
	</form>
</content:page>
~~~

This template would typically be designed with supporting `_page.xnode` and `_heading.xnode` in the same directory or, more typically, somewhere further up the directory hierarchy.

## Session

The {ruby Utopia::Session} middleware provides session storage using encrypted client-side cookies. The session management uses symmetric private key encryption to store data on the client and avoid tampering.

```ruby
use Utopia::Session,
	expires_after: 3600 * 24,
	# The private key is retried from the `environment.yaml` file:
	secret: UTOPIA.secret_for(:session),
	secure: true
```

All session data is stored on the client, but it's encrypted with a salt and the secret key. It is impossible for the client to decrypt the data without the secret stored on the server.
