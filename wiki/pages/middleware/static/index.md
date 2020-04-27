# Static

This middleware serves static files using the `mime-types` library. By default, it works with `Rack::Sendfile` and supports `ETag` based caching. Normally, you'd prefer to put static files into `public/_static` but it's also acceptable to put static content into `pages/` if it makes sense.

```ruby
use Utopia::Static,
	# The root path to serve files from:
	root: "path/to/root",
	# The mime-types to recognize/serve:
	types: [:default, :xiph],
	# Cache-Control header for files:
	cache_control: 'public, max-age=7200'
```
