# ![Utopia](materials/utopia.svg)

Utopia is a website generation framework which provides a robust set of tools to build highly complex dynamic websites. It uses the filesystem heavily for content and provides functions for interacting with files and directories as structure representing the website.

[![Development Status](https://github.com/socketry/utopia/workflows/Test/badge.svg)](https://github.com/socketry/utopia/actions?workflow=Test)

## Features

  - Designed for both content-based websites and applications. Does not depend on a database.
  - Supports flexible content localization based on industry recommendations.
  - Built directly on `protocol-http` with a small application and middleware interface.
  - Low latency and high throughput. Capable of 10,000+ requests/second out of the box.

## Usage

Please see the [project documentation](https://socketry.github.io/utopia/) for more details.

  - [Getting Started](https://socketry.github.io/utopia/guides/getting-started/index) - This guide explains how to set up a `utopia` website for local development and deployment.

  - [Middleware](https://socketry.github.io/utopia/guides/middleware/index) - This guide gives an overview of the different middleware used by Utopia.

  - [Server Setup](https://socketry.github.io/utopia/guides/server-setup/index) - This guide explains how to deploy a `utopia` web application.

  - [Integrating with JavaScript](https://socketry.github.io/utopia/guides/integrating-with-javascript/index) - This guide explains how to integrate JavaScript into your Utopia application.

  - [What is XNode?](https://socketry.github.io/utopia/guides/what-is-xnode/index) - This guide explains the `xnode` view layer and how it can be used to build efficient websites.

  - [Updating Utopia](https://socketry.github.io/utopia/guides/updating-utopia/index) - This guide explains how to update existing `utopia` websites.

## Releases

Please see the [project releases](https://socketry.github.io/utopia/releases/index) for all releases.

### v3.0.5

  - **Breaking** Remove support for JavaScript packages installed in `lib/components`; use `node_modules` instead.
  - **Breaking** Expose <code class="language-ruby">Utopia::Content::Middleware\#links</code> as the content link resolver rather than an indexed lookup method.
  - **Security** Authenticate encrypted session cookies using AES-256-GCM. Existing session cookies are invalidated.
  - Constrain content node local paths to the configured content root.
  - **Security** Redact sensitive exception report fields and make bounded request body attachments opt-in.
  - Return `416 Range Not Satisfiable` for unsatisfiable static file byte ranges.

### v3.0.0

The 3.0.x series is considered a development release while the protocol HTTP application and controller interfaces stabilize.

  - **Breaking** Require Ruby 3.3 or later.
  - **Breaking** Replace the Rack-centric application boundary with <code class="language-ruby">Utopia::Application</code> and <code class="language-ruby">Protocol::HTTP::Middleware</code>. Applications now use `config/application.rb` and `config/serve.rb` instead of `config.ru`.
  - **Breaking** Separate complete protocol responses from semantic controller results. Use `respond!` with a <code class="language-ruby">Protocol::HTTP::Response</code>, or `succeed!` with a value serialized by <code class="language-ruby">Utopia::Controller::Respond</code>.
  - Parse request bodies at the controller layer using `protocol-content`, independently of URL query parameters.
  - Resolve localization through immutable request preferences, avoiding repeated internal controller requests.
  - Split redirection handling into focused middleware for rewrites, moved resources, directory indexes, and error documents.
  - **Security** Fix handling of redirects that start with `//` to prevent open redirect vulnerabilities.
  - Normalize request URLs using `Protocol::URL` and use structured paths throughout the middleware stack.
  - Resolve static files through encoded URL paths, with improved `HEAD`, range, and validator handling.
  - Use `protocol-media` and `protocol-http` for response and language negotiation, removing the `http-accept` dependency.

### v2.31.0

  - Add agent context.
  - Better simplification of relative paths, e.g. `../../foo` is not modified to `foo`.
  - Move top level classes into `class Middleware` in their respective namespaces.
  - Move `Utopia::Responder` into `Utopia::Controller` layer.

### v2.30.1

  - Minor compatibility fixes.

### v2.27.0

  - Improved error logging using `Console` gem.
  - Only install `npm ls --production` dependencies into `public/_components`.

## See Also

  - [XRB](https://github.com/socketry/xrb) — Template and markup parsers, markup generation.
  - [Utopia::Gallery](https://github.com/ioquatix/utopia-gallery) — A fast photo gallery based on [libvips](https://github.com/jcupitt/libvips).
  - [Utopia::Project](https://github.com/socketry/utopia-project) — A Ruby project documentation tool.
  - [Utopia::Analytics](https://github.com/ioquatix/utopia-analytics) — Simple integration with Google Analytics.
  - [Samovar](https://github.com/ioquatix/samovar) — Command line parser used by Utopia.
  - [Mapping](https://github.com/ioquatix/mapping) — Provide structured conversions for web interfaces.

### Examples

  - [Financier](https://github.com/ioquatix/financier) — A small business management platform.
  - [mail.oriontransfer.net](https://github.com/oriontransfer/mail.oriontransfer.net) - Mail server account management.
  - [www.codeotaku.com](http://www.codeotaku.com) ([source](https://github.com/ioquatix/www.codeotaku.com)) — Personal website, blog.

## Contributing

We welcome contributions to this project.

1.  Fork it.
2.  Create your feature branch (`git checkout -b my-new-feature`).
3.  Commit your changes (`git commit -am 'Add some feature'`).
4.  Push to the branch (`git push origin my-new-feature`).
5.  Create new Pull Request.

### Running Tests

To run the test suite:

``` shell
bundle exec sus
```

### Making Releases

To make a new release:

``` shell
bundle exec bake gem:release:patch # or minor or major
```

### Developer Certificate of Origin

In order to protect users of this project, we require all contributors to comply with the [Developer Certificate of Origin](https://developercertificate.org/). This ensures that all contributions are properly licensed and attributed.

### Community Guidelines

This project is best served by a collaborative and respectful environment. Treat each other professionally, respect differing viewpoints, and engage constructively. Harassment, discrimination, or harmful behavior is not tolerated. Communicate clearly, listen actively, and support one another. If any issues arise, please inform the project maintainers.
