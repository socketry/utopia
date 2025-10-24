# Integrating with JavaScript

This guide explains how to integrate JavaScript into your Utopia application.

## Using Import Maps

Import maps provide a modern way to manage JavaScript module dependencies. Utopia includes built-in support for import maps through the {ruby Utopia::ImportMap} class.

### Installing JavaScript Libraries

First, install the library using npm:

```bash
$ npm install jquery
```

Copy the distribution files to `public/_components`:

```bash
$ bundle exec bake utopia:node:update
```

This will copy the library's distribution files (typically from `node_modules/*/dist/`) to your `public/_components/` directory, making them available for local serving.

### Creating the Import Map

Create a global import map in `lib/my_website/import_map.rb`:

```ruby
require "utopia/import_map"

module MyWebsite
	IMPORT_MAP = Utopia::ImportMap.build(base: "/_components/") do |map|
		map.import("jquery", "./jquery/jquery.js")
	end
end
```

Then load this in `lib/my_website.rb`:

```ruby
require_relative "my_website/import_map"
```

### Adding to Your Pages

Add it to your page template (`pages/_page.xnode`), using `relative_to` to adjust paths for the current page:

```xrb
<html>
	<head>
		#{MyWebsite::IMPORT_MAP.relative_to(request.path + "/")}
	</head>
	<body>
		<!-- Your content -->
	</body>
</html>
```

### Using the Library

Once the import map is set up, you can import and use the library in your scripts:

```xrb
<script type="module">
	// <![CDATA[
	import $ from 'jquery';
	
	$(document).ready(function() {
		console.log("jQuery is ready!");
	});
	// ]]>
</script>
```


### Advanced Import Map Features

#### Using CDN URLs

Import maps support direct CDN imports without downloading files:

```ruby
IMPORT_MAP = Utopia::ImportMap.build do |map|
	map.import("react", "https://esm.sh/react@18")
	map.import("vue", "https://cdn.jsdelivr.net/npm/vue@3/dist/vue.esm-browser.js")
end
```

#### Nested Base URLs

You can organize imports from different sources using nested `with(base:)` blocks:

```ruby
IMPORT_MAP = Utopia::ImportMap.build do |map|
	# Local components
	map.with(base: "/_components/") do |local|
		local.import "app", "./app.js"
	end
	
	# CDN imports
	map.with(base: "https://cdn.jsdelivr.net/npm/") do |cdn|
		cdn.import "lit", "lit@2.7.5/index.js"
		cdn.import "lit/decorators.js", "lit@2.7.5/decorators.js"
	end
end
```

#### Subresource Integrity

Add integrity hashes for enhanced security:

```ruby
IMPORT_MAP = Utopia::ImportMap.build do |map|
	map.import("react", "https://esm.sh/react@18", integrity: "sha384-...")
end
```

#### Scoped Imports

Use scopes to resolve imports differently based on the **referrer URL** (the page or module location where the import is being made):

```ruby
IMPORT_MAP = Utopia::ImportMap.build do |map|
	map.import("utils", "/utils.js")
	
	# When importing from any page under /admin/, use a different utils module
	map.scope("/admin/", {"utils" => "/admin/utils.js"})
end
```

When you're on a page at `/admin/dashboard` and you `import "utils"`, it will resolve to `/admin/utils.js`. On other pages, it resolves to `/utils.js`.

## Traditional JavaScript

You can also use JavaScript by embedding it directly into your HTML, or by creating a JavaScript source file and referencing that.

### Embedding Code

When embedding JavaScript directly in XRB templates, wrap the code in CDATA comments to prevent XRB's parser from interpreting special characters like `<`, `>`, and `&`:

```xrb
<html>
	<body>
		<script type="text/javascript">
			// <![CDATA[
			console.log("Hello World")
			// ]]>
		</script>
	</body>
</html>
```

### External Script

In `script.js`:

```javascript
console.log("Hello World")
```

In your HTML view:

```xrb
<html>
	<body>
		<script type="text/javascript" src="script.js"></script>
	</body>
</html>
```
