# Bower Integration

Utopia integrates with Bower and provides a rake task to improve deployment of `dist` code.

By default, utopia includes a `.bowerrc` file which installs modules into `lib/components`. This code can then be copied into `public/_components` using `rake bower:update`.

## Installing jQuery

Firstly install jquery using bower:

	$ bower install jquery

Copy the distribution scripts to `public/_components`:

	$ rake bower:update

Then add the appropriate `<script>` tags to `pages/_page.xnode`:

	<script src="/_components/jquery/jquery.min.js" type="text/javascript"></script>

## What does `rake bower:update` do?

This task copies only the contents of the dist directory. This ensures that you only get files intended for distribution. If the bower package doesn't have a `dist` directory, the entire contents is copied.

<fragment:listing rel="site" src="tasks/bower.rake" brush="ruby" />
