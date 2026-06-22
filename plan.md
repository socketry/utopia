# Utopia v3 Protocol HTTP Application Design

## Direction

Utopia v3 should move the core application interface from Rack to `protocol-http`.
Rack support can remain available through an adapter, but it should no longer be the
internal ABI for requests, responses, middleware, sessions, static files, or
controllers.

The main goal is to keep the HTTP boundary small while giving Utopia its own
application request shape. Rack has been valuable because it codifies request,
response, and middleware conventions, but that same shared surface has made it hard
to evolve and hard for application frameworks to make different performance,
security, and usability choices.

## Layering

The proposed stack is:

```text
Protocol::HTTP::Request
  -> Utopia::Application
  -> Utopia::Request
  -> Utopia application middleware/controllers/content
  -> Utopia::Response or Protocol::HTTP::Response shaped value
  -> Protocol::HTTP::Response
```

`Utopia::Application` is the adaptation boundary. Everything above it is ordinary
`protocol-http` middleware. Everything below it is Utopia application middleware.

## Application

`Utopia::Application` should be directly usable anywhere a
`Protocol::HTTP::Middleware` is expected:

```text
application = Utopia::Application.load
application.call(protocol_http_request)
application.close
```

Construction should keep object construction separate from DSL configuration:

```text
Application = Utopia::Application.build do
	use Utopia::Static, root: "public"
	use Utopia::Controller
	run Utopia::Content
end
```

Preferred API:

```text
Utopia::Application.new(delegate, **options)
Utopia::Application.build(**options) { ... }
Utopia::Application.load(path = "config/application.rb", **options)
Utopia::Application.default(**options)
```

Responsibilities:

- `new` wraps an already-built Utopia application stack.
- `build` evaluates the Utopia middleware DSL and returns a protocol-compatible
  application.
- `load` loads the conventional application file and returns the configured
  application.
- `default` returns a useful default Utopia site stack.

Avoid accepting a block to `initialize`; use `Application.build do ... end` for
DSL configuration.

`Utopia::Application.build` may use `Protocol::HTTP::Middleware::Builder`
internally for mechanical stack composition. Utopia does not need to expose a
separate builder class unless the DSL needs to diverge from the protocol builder.

Even when the protocol builder is used internally, `Utopia::Application.build`
defines the Utopia application middleware contract and owns compatibility for
Utopia middleware.

## Application Configuration

The canonical app file should be:

```text
config/application.rb
```

It should define a top-level `Application` constant:

```text
require "utopia"

Application = Utopia::Application.build do
	use Utopia::Static, root: "public"
	use Utopia::Controller
	run Utopia::Content
end
```

The loader should also support a default when no `Application` constant exists.
This mirrors the useful pattern in Lively: a top-level `Application` constant for
normal projects, with a default fallback for quick starts and generic tooling.

The `Application` constant may be either:

- a configured middleware object, or
- a class/subclass that can be instantiated as protocol middleware.

Utopia should normalize both cases internally.

## Falcon Configuration

Use the modern Falcon service definition shape. Do not use the old
`load :supervisor` style.

Explicit app configuration:

```text
require_relative "config/application"

service "utopia" do
	include Falcon::Environment::Server
	
	def middleware
		Application
	end
end
```

Generic/default configuration:

```text
require "utopia"

service "utopia" do
	include Falcon::Environment::Server
	
	def middleware
		Utopia::Application.load
	end
end
```

## Request

Introduce `Utopia::Request` as the application request shape. It should be thin,
explicit, and lazy, not a reimplementation of `Rack::Request`.

Likely shape:

```text
request.http
request.method
request.path
request.path_info
request.path_info=
request.query
request.headers
request.cookies
request.body
request.arguments
request.session
request.variables
request.locale
request.attributes
```

Guidelines:

- Keep `request.http` available for direct access to the underlying
  `Protocol::HTTP::Request`.
- Avoid a global magical `params` hash.
- Prefer `arguments` over `params`.
- Parse request data lazily.
- Keep query, form, JSON, and multipart parsing separable where possible.
- Use Utopia-owned request-local state rather than Rack-style `env`.

Possible arguments shape:

```text
request.arguments.query
request.arguments.form
request.arguments.json
request.arguments.multipart
```

## Response

Use `Protocol::HTTP::Response` as the canonical transport response.

`Utopia::Response` should be a helper/factory/normalizer, not necessarily a
mandatory rich response object:

```text
Utopia::Response[200, {"content-type" => "text/plain"}, ["Hello"]]
Utopia::Response.redirect("/target")
Utopia::Response.text("Hello")
Utopia::Response.html(document)
```

Application middleware and controllers may return:

- `Protocol::HTTP::Response`
- `Utopia::Response` values
- compatible response tuples, if supported during migration

Normalize at the `Utopia::Application` boundary.

## Middleware

There should be two explicit middleware layers:

1. HTTP middleware, operating on `Protocol::HTTP::Request` and
   `Protocol::HTTP::Response`.
2. Utopia application middleware, operating on `Utopia::Request`.

HTTP middleware is appropriate for low-level protocol behavior, tracing,
compression, authority policy, early routing, static transport optimizations, and
protocol upgrades.

Application middleware is appropriate for sessions, localization, arguments,
content negotiation, controller variables, CSRF, authentication, and other
framework-specific semantics.

The regular Utopia DSL should compose application middleware:

```text
Utopia::Application.build do
	use Utopia::Session
	use Utopia::Localization, locales: ["en", "ja"]
	run Utopia::Content
end
```

Utopia owns what `use` and `run` mean for application middleware. The app
middleware contract should be:

```text
initialize(delegate, ...)
call(Utopia::Request) -> response-like value
```

and terminal apps should satisfy:

```text
call(Utopia::Request) -> response-like value
```

`Utopia::Application.build` can decide compatibility details such as:

- whether `use` accepts classes, objects, or both.
- whether `run Utopia::Content, root: ...` instantiates the app automatically.
- whether `close` is propagated through the stack.
- whether middleware may return `nil` to pass through.
- whether middleware may mutate `request.path_info`.

Do not try to preserve Rack middleware compatibility in the core Utopia stack.

## Programmatic Applications

Frameworks and gems should be able to construct Utopia applications without relying
on project-level constants.

For example, `utopia-project` should move from mutating a Rack builder:

```text
Utopia::Project.call(builder)
```

to returning a protocol-compatible middleware:

```text
module Utopia
	module Project
		def self.application(root: Dir.pwd, locales: nil)
			Utopia::Application.build(root: root) do
				use Utopia::Static, root: root
				use Utopia::Static, root: PUBLIC_ROOT
				
				use Utopia::Redirection::Rewrite, "/" => "/index"
				use Utopia::Redirection::DirectoryIndex
				use Utopia::Redirection::Errors, 404 => "/errors/file-not-found"
				
				if locales
					use Utopia::Localization, default_locale: locales.first, locales: locales
				end
				
				use Utopia::Controller, root: PAGES_ROOT
				run Utopia::Content, root: PAGES_ROOT
			end
		end
	end
end
```

Consumers can then choose:

```text
Application = Utopia::Project.application
```

or:

```text
app = Utopia::Project.application(root: "/path/to/project")
```

## Shared Gem

Do not extract a shared `protocol-http-application` gem initially.

The generic code is likely small, and the useful pieces quickly become
framework-specific: default root, default file name, fallback behavior, request
wrapper, response helpers, error behavior, middleware DSL, and constant
resolution.

Keep the implementation in Utopia first. Extract later only if multiple frameworks
end up sharing the same stable, low-opinion code.

## Migration Notes

Expected breaking changes:

- Core Utopia middleware no longer receives Rack env hashes.
- Controllers no longer receive `Rack::Request`.
- `env[...]`, `rack.session`, `rack.input`, and Rack response tuple assumptions
  need migration.
- Static file serving should move away from `Rack::Sendfile` and Rack range
  helpers.
- `config.ru` is no longer the native boot path. Use `config/application.rb`.
- Tests should move from `rack-test` to protocol-http/async-http oriented tests.

Useful preparatory work before the v3 transport change:

- Introduce internal request/response helpers while still Rack-backed.
- Replace direct `Rack::PATH_INFO`, `Rack::HTTP_HOST`, etc. usage with local
  accessors.
- Move cookie parsing and serialization behind Utopia-owned helpers.
- Isolate static range/sendfile behavior from `Rack::Utils`.
- Make session storage names Utopia-native.
- Start normalizing response values internally.
