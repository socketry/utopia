# Getting Started

This guide explains how to set up a `utopia` website for local development and deployment.

## Installation

Utopia is built on Ruby and Rack. Therefore, Ruby (suggested 2.0+) should be installed and working. Then, to install `utopia` and all required dependencies, run:

~~~ bash
$ gem install utopia
~~~

### Atom Integration

Utopia uses [Trenni](https://github.com/ioquatix/trenni) for templates and it has a syntax slightly different from ERB. However, there is a [package for Atom](https://atom.io/packages/language-trenni) which provides accurate syntax highlighting.

## Your First Page

To setup the default site, create a directory (typically the hostname of the site you want to create) and use the `bake utopia:site:create` command:

~~~ bash
$ mkdir www.example.com
$ cd www.example.com
$ bake --gem utopia utopia:site:create
$ bake utopia:development
~~~

You will now have a basic template site running on `https://localhost:9292`.

### Welcome Page

Utopia includes a redirection middleware to redirect all root-level requests to a given URI. The default being `/welcome/index`:

```ruby
# in config.ru

use Utopia::Redirection::Rewrite,
	'/' => '/welcome/index'
```

The content for this page is stored in `pages/welcome/index.xnode`. The format of this page is a subset of HTML5 - open and close tags are strictly enforced.

There are several special tags which are used for creating modular content. The most common one is the outer `<content:page>` tag. Utopia uses the name `page` to lookup the file-system hierarchy. First, it looks for `/welcome/_page.xnode`, and then it looks for `/_page.xnode` which it finds. This page template includes a special `<utopia:content/>` tag which is replaced with the inner body of the `<content:page>` tag. This recursive lookup is the heart of Utopia.

### Links

Utopia is a content-centric web application platform. It leverages the file-system to provide a mapping between logical resources and files on disk. The primary mode of mapping incoming requests to specific nodes (content) is done using the `links.yaml` file.

The links file associates metadata with node names for a given directory. This can include things like redirects, titles, descriptions, etc. You can add any metadata you like, to support your specific use-case. The primary use of the links files is to provide site structure, e.g. menus. In addition, they can function as a rudimentary data-store for static information, e.g. a list of applications (each with it's own page), a list of features, etc.

You'll notice that there is a file `/links.yaml`. This file contains important metadata relating to the `errors` subdirectory. As we don't want these nodes showing up in a top level menu, we mark them as `display: false`

~~~ yaml
errors:
  display: false 
~~~

## Testing

Utopia websites include a default set of tests using `sus`. These specs can test against the actual running website.

~~~ bash
$ sus

1 samples: 1x 200. 3703.7 requests per second. S/D: 0.000µs.
1 passed out of 1 total (2 assertions)
🏁 Finished in 247.4ms; 8.085 assertions per second.
~~~

The website test will spider all pages on your site and report any broken links as failures.

### Coverage

The [covered](https://github.com/socketry/covered) gem is used for providing source code coverage information.

~~~ bash
$ COVERAGE=BriefSummary rspec

website
1 samples: 1x 200. 67.53 requests per second. S/D: 0.000µs.
  should be responsive

* 5 files checked; 33/46 lines executed; 71.74% covered.

Least Coverage:
pages/_page.xnode: 6 lines not executed!
config.ru: 4 lines not executed!
pages/welcome/index.xnode: 2 lines not executed!
pages/_heading.xnode: 1 lines not executed!

Finished in 1.82 seconds (files took 0.51845 seconds to load)
1 example, 0 failures
~~~
