# ![Utopia Logo](materials/utopia.svg)

Utopia is a website generation framework which provides a robust set of tools to build highly complex dynamic websites. It uses the filesystem heavily for content and provides functions for interacting with files and directories as structure representing the website.

[![Build Status](https://secure.travis-ci.org/ioquatix/utopia.svg)](http://travis-ci.org/ioquatix/utopia)
[![Code Climate](https://codeclimate.com/github/ioquatix/utopia.svg)](https://codeclimate.com/github/ioquatix/utopia)
[![Coverage Status](https://coveralls.io/repos/ioquatix/utopia/badge.svg)](https://coveralls.io/r/ioquatix/utopia)

## Motivation

The [original Utopia project](https://github.com/ioquatix/utopia-php) was written in PHP in the early 2000s. It consisted of an XML parser, a database layer and some code to assist with business logic. It was initially designed to reduce the amount of HTML required to build both content-centric websites and business apps. At the time, CSS was very poorly supported and thus a lot of the time, you'd be using quite complex `<table>`s with embedded `<img>`s to generate simple things like boxes with drop shadows, etc. Utopia provided a core concept - a node - which was essentially a small snippet of HTML, which could be composed into other nodes simply by using a named tag (similar to ColdFusion). Attributes and content were passed in, and thus you could easily build complex pages with simple semantic markup.

At the time, the available frameworks were pretty basic. Utopia was a working, albeit poor, implementation of MVC and supported several commercial websites I developed at the time. I made it, partly just because I could, but also because it served a commercial purpose.

Eventually one day I started using Ruby on Rails. There are aspects of the Rails framework which I like. However, at the time I was using it (starting with version 0.8), I found that it's flat organisation of controllers and views very limiting. Nested controllers and views make it easier to manage complexity in a web application. Utopia embraces this principle, and applies it to both the controller and view layers. I also developed a [model layer with similar principles](https://github.com/ioquatix/relaxo-model).

So, Utopia exists because it suits my way of thinking about web applications, and it's conceptual core has been refined for over a decade. It provides a considered amount of both flexibility, and opinionated behavior.

### Is it production ready?

Yes. We've used Utopia since about 2010 in production.

### Is it fast?

Yes. [Trenni](https://github.com/ioquatix/trenni) includes native [Ragel](http://www.colm.net/open-source/ragel/) parsers, and Utopia uses [Concurrent::Map](https://github.com/ruby-concurrency/concurrent-ruby) for multi-thread safe caches. On my laptop, Utopia can process 3000 requests/s rendering content on a single thread.

## Installation

Install utopia:

	$ gem install utopia

Create a new site:

	$ mkdir www.example.com
	$ cd www.example.com
	$ utopia site create
	$ rake

## Usage

There is an excellent documentation wiki included with the source code. Simply clone this repository and `rake documentation`. This documentation wiki is editable, so feel free to submit a PR with improvements.

## Contributing

1. Fork it
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create new Pull Request

## See Also

- [Trenni](https://github.com/ioquatix/trenni) — Template and markup parsers, markup generation.
- [Trenni::Formatters](https://github.com/ioquatix/trenni-formatters) — Helpers for HTML generation including views and forms.
- [Utopia::Gallery](https://github.com/ioquatix/utopia-gallery) — A fast photo gallery based on [libvips](https://github.com/jcupitt/libvips).
- [Utopia::Analytics](https://github.com/ioquatix/utopia-analytics) — Simple integration with Google Analytics.
- [Rack::Freeze](https://github.com/ioquatix/rack-freeze) — Multi-thread safety in Rack.
- [HTTP::Accept](https://github.com/ioquatix/http-accept) — RFC compliant header parser.
- [Samovar](https://github.com/ioquatix/samovar) — Command line parser used by Utopia.
- [Mapping](https://github.com/ioquatix/mapping) — Provide structured conversions for web interfaces.
- [Rack::Test::Body](https://github.com/ioquatix/rack-test-body) — Provide convenient helpers for testing web interfaces.

### Applications

- [Financier](https://github.com/ioquatix/financier) — A small business management platform.
- [mail.oriontransfer.net](https://github.com/oriontransfer/mail.oriontransfer.net) - Mail server account management.

## License

Released under the MIT license.

Copyright, 2017, by [Samuel G. D. Williams](http://www.codeotaku.com/samuel-williams).

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in
all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
THE SOFTWARE.
