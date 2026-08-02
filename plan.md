# Utopia v3 Protocol HTTP Application Design.

## Direction.

Utopia v3 should move the core application interface from Rack to `protocol-http`.
Rack support can remain available through an adapter, but it should no longer be the
internal ABI for requests, responses, middleware, sessions, static files, or
controllers.

The main goal is to keep the HTTP boundary small while letting Utopia own
application state explicitly. Rack has been valuable because it codifies request,
response, and middleware conventions, but that same shared surface has made it hard
to evolve and hard for application frameworks to make different performance,
security, and usability choices.

## Layering.

The proposed stack is:

```text
Protocol::HTTP::Request
  -> Utopia::Application
  -> Utopia middleware/controllers/content
  -> Utopia::Response or Protocol::HTTP::Response shaped value
  -> Protocol::HTTP::Response
```

`Utopia::Application` is the lifecycle boundary. It receives
`Protocol::HTTP::Request`, explicitly constructs a `Utopia::Request` wrapper for
application-facing request handling, installs that wrapper as ambient request
state, dispatches Utopia middleware with the wrapper, and normalizes the
response. The wrapper delegates the protocol request interface, so ordinary
HTTP middleware can continue to use the request argument without knowing about
Utopia-specific parsing and convenience methods.

## Application.

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

## Application Configuration.

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

## Falcon Configuration.

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

## Request And State.

`Utopia::Request` is a composition-based proxy around
`Protocol::HTTP::Request`. `Utopia::Application` constructs it once at the
protocol boundary, installs it as `Utopia::Request.current`, and passes the same
proxy explicitly through the Utopia middleware stack.

The proxy stores the protocol request as `@delegate` and delegates its public
interface with `method_missing` and `respond_to_missing?`. Utopia defines methods
only where it adds application semantics, caching, or rewrite tracking. The
inherited Ruby methods `method` and `to_s` are undefined so those protocol
request methods also pass through normal delegation. The
`Protocol::HTTP::Request` interface is expected to remain stable, so no general
collision-detection mechanism is required.

Current shape:

```text
Utopia::Request.current
Utopia::Request.current = request
Utopia::Request.current!

utopia_request.delegate
utopia_request.method
utopia_request.path
utopia_request.path_info
utopia_request.path_info=
utopia_request.query
utopia_request.headers
utopia_request.cookies
utopia_request.body
utopia_request.arguments
```

Guidelines:

- Do not retain Rack request or environment compatibility APIs.
- Prefer `arguments` over `params`.
- Parse request data lazily.
- Keep query, form, JSON, and multipart parsing separable where possible.
- Do not monkey patch `Protocol::HTTP::Request`; Utopia-specific convenience
  methods belong on `Utopia::Request`.
- Pass `Utopia::Request` explicitly as the middleware request argument.
- Keep the protocol request available as `request.delegate` for integrations
  which specifically require the concrete protocol object.
- Do not expose generic ambient `Utopia.request` style state; use
  `Utopia::Request.current` for request-adjacent ambient access.
- Store request-scoped state such as sessions on `Utopia::Request` rather than
  in Rack-style `env` or generic ambient state.
- Derived requests should duplicate the protocol delegate, preserve the original
  request path, be passed explicitly downstream, and temporarily replace
  `Utopia::Request.current` for the derived invocation.

Possible arguments shape:

```text
utopia_request.arguments.query
utopia_request.arguments.form
utopia_request.arguments.json
utopia_request.arguments.multipart
```

Framework state should be exposed through named Utopia APIs:

```text
request.session[:user_id]
request.session[:user_id] = 10
Utopia::Request.current
Utopia::Controller.current
Utopia::Controller.current!
Utopia::Localization.current
```

The implementation can store this directly in fiber storage:

```text
Fiber[:utopia_request]
Fiber[:utopia_variables]
Fiber[:utopia_current_locale]
```

Ambient subsystems should own their own `current`/`current=` API for tests and
middleware setup. Since each request is handled by an independent fiber, a
separate root context object is not needed. Sessions are not ambient: session
middleware attaches the session directly to `Utopia::Request`, where it remains
`nil` when the middleware is not installed.

Session mutation should be owned by the fiber that constructed the session and
should be rejected after commit. Other fibers may receive the request and read its
session, but writes from non-owner fibers should fail. This makes session races
visible and matches the fact that only the request-owning fiber can reliably
commit the session back to the response.

## Response.

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

## Middleware.

Utopia middleware should use the protocol-http middleware shape:

```text
initialize(delegate, ...)
call(Utopia::Request) -> response-like value
```

Low-level protocol behavior, tracing, compression, authority policy, early
routing, static transport optimizations, and protocol upgrades can use the
delegated protocol interface on the request argument. Framework-specific
semantics such as path parsing, localization, content negotiation, controllers,
CSRF, and authentication can use the richer `Utopia::Request` interface.
Sessions are available through the request argument. Controller variables and
other optional adjacent state remain available through their named ambient APIs.
Utopia owns the compatibility of its middleware APIs and request-local state helpers.

The regular Utopia DSL should compose application middleware:

```text
Utopia::Application.build do
	use Utopia::Session
	use Utopia::Localization, locales: ["en", "ja"]
	run Utopia::Content
end
```

Utopia owns what `use` and `run` mean for middleware. Terminal apps should
satisfy:

```text
call(Utopia::Request) -> response-like value
```

`Utopia::Application.build` can decide compatibility details such as:

- whether `use` accepts classes, objects, or both.
- whether `run Utopia::Content, root: ...` instantiates the app automatically.
- whether `close` is propagated through the stack.
- whether middleware may return `nil` to pass through.
- whether middleware may derive a new `Utopia::Request.current` and pass the
  derived request downstream for internal rewrites.

Do not try to preserve Rack middleware compatibility in the core Utopia stack.

## Programmatic Applications.

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

## Shared Gem.

Do not extract a shared `protocol-http-application` gem initially.

The generic code is likely small, and the useful pieces quickly become
framework-specific: default root, default file name, fallback behavior, request
helpers, fiber state APIs, response helpers, error behavior, middleware DSL, and
constant resolution.

Keep the implementation in Utopia first. Extract later only if multiple frameworks
end up sharing the same stable, low-opinion code.

## Migration Notes.

Expected breaking changes:

- Core Utopia middleware no longer receives Rack env hashes.
- Controllers no longer receive `Rack::Request`.
- Core Utopia middleware receives `Utopia::Request`, which delegates the
  `Protocol::HTTP::Request` interface.
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

## Remaining Cleanup.

Completed before landing the v3 application boundary:

- [x] Remove the `Utopia::Request#params` alias. `arguments` is the intentional
  application-facing name.
- [x] Remove the Rack-style `Utopia::Request#[]` mappings for `REQUEST_METHOD`,
  `PATH_INFO`, `QUERY_STRING`, `HTTP_*`, and related environment keys. Callers
  should use request methods, headers, and `arguments` directly.
- [x] Update the exception mailer to collect named request methods and headers rather
  than iterating Rack environment key names.
- [x] Update README and guide text that still describes Utopia middleware or response
  bodies in terms of Rack.
- [x] Keep the protocol-facing `Utopia::Application#call` boundary documented as
  accepting `Protocol::HTTP::Request`; document internal middleware as accepting
  `Utopia::Request`.
- [x] Retain focused proxy tests for delegation, introspection, unknown methods,
  setters, duplication, and the known `method`/`to_s` Ruby collisions.
