# ![Utopia](materials/utopia.svg)

Utopia is a website generation framework which provides a robust set of tools to build highly complex dynamic websites. It uses the filesystem heavily for content and provides functions for interacting with files and directories as structure representing the website.

[![Development Status](https://github.com/ioquatix/utopia/workflows/Test/badge.svg)](https://github.com/ioquatix/utopia/actions?workflow=Test)

## Features

  - Designed for both content-based websites and applications. Does not depend on a database.
  - Supports flexible content localization based on industry recommendations.
  - Rack middleware compatible with all major Ruby application servers. Small memory footprint by default.
  - Low latency and high throughput. Capable of 10,000+ requests/second out of the box.

## Usage

Please see the [project documentation](https://socketry.github.io/utopia).

## Contributing

We welcome contributions to this project.

1.  Fork it.
2.  Create your feature branch (`git checkout -b my-new-feature`).
3.  Commit your changes (`git commit -am 'Add some feature'`).
4.  Push to the branch (`git push origin my-new-feature`).
5.  Create new Pull Request.

## See Also

  - [Trenni](https://github.com/ioquatix/trenni) — Template and markup parsers, markup generation.
  - [Trenni::Formatters](https://github.com/ioquatix/trenni-formatters) — Helpers for HTML generation including views and forms.
  - [Utopia::Gallery](https://github.com/ioquatix/utopia-gallery) — A fast photo gallery based on [libvips](https://github.com/jcupitt/libvips).
  - [Utopia::Project](https://github.com/socketry/utopia-project) — A Ruby project documentation tool.
  - [Utopia::Analytics](https://github.com/ioquatix/utopia-analytics) — Simple integration with Google Analytics.
  - [HTTP::Accept](https://github.com/ioquatix/http-accept) — RFC compliant header parser.
  - [Samovar](https://github.com/ioquatix/samovar) — Command line parser used by Utopia.
  - [Mapping](https://github.com/ioquatix/mapping) — Provide structured conversions for web interfaces.
  - [Rack::Test::Body](https://github.com/ioquatix/rack-test-body) — Provide convenient helpers for testing web interfaces.

### Examples

  - [Financier](https://github.com/ioquatix/financier) — A small business management platform.
  - [mail.oriontransfer.net](https://github.com/oriontransfer/mail.oriontransfer.net) - Mail server account management.
  - [www.codeotaku.com](http://www.codeotaku.com) ([source](https://github.com/ioquatix/www.codeotaku.com)) — Personal website, blog.
