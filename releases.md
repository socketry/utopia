# Releases

## v3.0.7

### Web Packages

Utopia now uses `web-packages` v0.2 after the project was renamed from `bake-node`. Applications should use the `web-packages` key in `package.json` and invoke package management through the `web:packages` Bake namespace. The generated `.manifest.json` format remains compatible.

## v3.0.6

### JavaScript Packages

Utopia now depends on `bake-node` for JavaScript dependency installation and static package projection. `Utopia::Components` and `utopia:components:update` have been removed. Replace the old task with `bundle exec bake node:packages:static`, and migrate package selection from `utopia.components` to `bake-node.packages` in `package.json`.

Use `Utopia::ImportMap.load_manifest("public/_components")` to load the generated browser import mappings directly from the Bake Node manifest.

## v3.0.5

  - **Breaking** Remove support for JavaScript packages installed in `lib/components`; use `node_modules` instead.
  - **Breaking** Expose {ruby Utopia::Content::Middleware\#links} as the content link resolver rather than an indexed lookup method.
  - **Security** Authenticate encrypted session cookies using AES-256-GCM. Existing session cookies are invalidated.
  - Constrain content node local paths to the configured content root.
  - **Security** Redact sensitive exception report fields and make bounded request body attachments opt-in.
  - Return `416 Range Not Satisfiable` for unsatisfiable static file byte ranges.

## v3.0.0

The 3.0.x series is considered a development release while the protocol HTTP application and controller interfaces stabilize.

  - **Breaking** Require Ruby 3.3 or later.
  - **Breaking** Replace the Rack-centric application boundary with {ruby Utopia::Application} and {ruby Protocol::HTTP::Middleware}. Applications now use `config/application.rb` and `config/serve.rb` instead of `config.ru`.
  - **Breaking** Separate complete protocol responses from semantic controller results. Use `respond!` with a {ruby Protocol::HTTP::Response}, or `succeed!` with a value serialized by {ruby Utopia::Controller::Respond}.
  - Parse request bodies at the controller layer using `protocol-content`, independently of URL query parameters.
  - Resolve localization through immutable request preferences, avoiding repeated internal controller requests.
  - Split redirection handling into focused middleware for rewrites, moved resources, directory indexes, and error documents.
  - **Security** Fix handling of redirects that start with `//` to prevent open redirect vulnerabilities.
  - Normalize request URLs using `Protocol::URL` and use structured paths throughout the middleware stack.
  - Resolve static files through encoded URL paths, with improved `HEAD`, range, and validator handling.
  - Use `protocol-media` and `protocol-http` for response and language negotiation, removing the `http-accept` dependency.

## v2.31.0

  - Add agent context.
  - Better simplification of relative paths, e.g. `../../foo` is not modified to `foo`.
  - Move top level classes into `class Middleware` in their respective namespaces.
  - Move `Utopia::Responder` into `Utopia::Controller` layer.

## v2.30.1

  - Minor compatibility fixes.

## v2.27.0

  - Improved error logging using `Console` gem.
  - Only install `npm ls --production` dependencies into `public/_components`.
