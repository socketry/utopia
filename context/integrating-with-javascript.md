# Installing JavaScript Libraries

Utopia integrates with Yarn and provides a [bake task](https://github.com/ioquatix/bake) to simplify deployment packages distributed using `yarn` that implement the `dist` sub-directory convention.

## Installing Yarn

If you don't already have yarn installed, make sure you have npm installed and then run the following command:

```bash
$ sudo npm install -g yarn
```

## Installing jQuery

Firstly, ensure your project has a `package.json` file:

```bash
$ yarn init
```

Then install jquery using `yarn`:

```bash
$ yarn add jquery
```

Copy the distribution scripts to `public/_components`:

```bash
$ bundle exec bake utopia:node:update
```

Then add the appropriate `<script>` tags to `pages/_page.xnode`:

```html
<script type="text/javascript" src="/_components/jquery/jquery.min.js"></script>
```

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