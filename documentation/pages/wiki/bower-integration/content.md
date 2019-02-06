# Bower Integration

Utopia integrates with Bower and provides a rake task to simplify deployment packages distributed using `bower` that implement the `dist` sub-directory convention.

By default, utopia includes a `.bowerrc` file which installs modules into `lib/components`. This code can then be copied into `public/_components` using `rake bower:update`.

## Installing jQuery

Firstly install jquery using bower:

	$ bower install jquery

Copy the distribution scripts to `public/_components`:

	$ rake bower:update

Then add the appropriate `<script>` tags to `pages/_page.xnode`:

```html
<script type="text/javascript" src="/_components/jquery/jquery.min.js"></script>
```

### What does `rake bower:update` do?

This task copies only the contents of the dist directory. This ensures that you only get files intended for distribution. If the bower package doesn't have a `dist` directory, the entire contents is copied.

<fragment:listing rel="site" src="tasks/bower.rake" brush="ruby" />

## Using JavaScript

You can use JavaScript by embedding it directly into your HTML, or by creating a JavaScript source file and referencing that.

### Embedding Code

In your HTML view:

```trenni
<html>
  <body>
    <script type="text/javascript">
      //<![CDATA[
      console.log("Hello World")
      //]]>
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

```trenni
<html>
  <body>
    <script type="text/javascript" src="script.js"></script>
  </body>
</html>
```