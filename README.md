# Utopia

Utopia is a website generation framework which provides a robust set of tools
to build highly complex dynamic websites. It uses the filesystem heavily for
content and provides frameworks for interacting with files and directories as
structure representing the website.

Utopia builds on top of Rack with the following middleware:

* `Utopia::Middleware::Static`: Serve static files with recursive lookup
* `Utopia::Middleware::Requester`: Allow nesting of virtual requests
* `Utopia::Middleware::Redirector`: Redirect URL patterns and status codes
* `Utopia::Middleware::Logger`: Advanced rotating access log
* `Utopia::Middleware::Localization`: Non-intrusive localization of resources
* `Utopia::Middleware::DirectoryIndex`: Redirect directory requests to specific files
* `Utopia::Middleware::Controller`: Dynamic behaviour with recursive execution
* `Utopia::Middleware::Content`: XML-style template engine with powerful tag behaviours
* `Utopia::Session::EncryptedCookie`: Session storage using an encrypted cookie

For more details please see the main [project page][1].

[1]: http://www.oriontransfer.co.nz/gems/utopia

[![Build Status](https://secure.travis-ci.org/ioquatix/utopia.png)](http://travis-ci.org/ioquatix/utopia)

## Installation

Install utopia:

    $ gem install utopia

Create a new site:

	$ utopia setup www.example.com
	$ cd www.example.com
	$ thin start -p 9000

## Usage

The default site includes documentation and examples.

## Contributing

1. Fork it
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create new Pull Request

## License

Released under the MIT license.

Copyright, 2012, by [Samuel G. D. Williams](http://www.codeotaku.com/samuel-williams).

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