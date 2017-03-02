# Your First Page

To setup the default site, simply create a directory and use the `utopia` command:

```bash
$ mkdir www.example.com
$ cd www.example.com
$ utopia site create
$ rake server
```

You will now have a basic template site running on <a href="http://localhost:9292">http://localhost:9292</a>.

## Welcome Page

Utopia includes a redirection middleware to redirect all root-level requests to a given URI. The default being `/welcome/index`:

```ruby
use Utopia::Redirection::Rewrite,
	'/' => '/welcome/index'
```

This page includes a basic overview of Utopia. Most of it's standard HTML, except for the outer `<page>` tag. Utopia uses the name `page` to lookup the file-system hierarchy. First, it looks for `/welcome/_page.xnode`, and then it looks for `/_page.xnode` which it finds. This page template includes a tag `<content/>` which is replaced with the inner body of the `<page>` tag. This recursive lookup is the heart of Utopia.

## Links

Utopia is a content-centric web application platform. It leverages the file-system to provide a mapping between logical resources and files on disk. The primary mode of mapping incoming requests to specific nodes (content) is done using the `links.yaml` file.

The links file associates metadata with node names for a given directory. This can include things like redirects, titles, descriptions, etc. You can add any metadata you like, to support your specific use-case. The primary use of the links files is to provide site structure, e.g. menus. In addition, they can function as a rudimentary data-store for static information, e.g. a list of applications (each with it's own page), a list of features, etc.

You'll notice that there is a file `/links.yaml`. This file contains important metadata relating to the `errors` subdirectory. As we don't want these nodes showing up in a top level menu, we mark them as `display: false`

```yaml
errors:
    display: false 
```