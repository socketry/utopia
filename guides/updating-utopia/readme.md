# Updating Utopia

This guide explains how to update existing `utopia` websites.

## Overview

Utopia provides a model for both local development (`utopia site create`) and deployment (`utopia server create`). In addition, Utopia provides a basic upgrade path for existing sites when things within the framework change. These are not always automatic, so below are some recipes for how to update your site.

## Site Update

Utopia as a framework introduces changes and versions change according to semantic versioning. 

### Controller Update 1.9.x to 2.x

The controller layer no longer automatically prepends the `Actions` layer. The following program does a best effort attempt to update existing controllers:

```ruby
#!/usr/bin/env ruby

paths = Dir.glob("**/controller.rb")

paths.each do |path|
	lines = File.readlines(path)
	
	prepend_line_index = lines.first(5).find_index{|line| line =~ /prepend/}
	
	unless prepend_line_index
		puts "Updating #{path}.."
		File.open(path, "w") do |file|
			file.puts "\nprepend Actions"
			file.write lines.join
		end
	else
		prepend_line = lines[prepend_line_index]
		
		unless prepend_line =~ /Actions/
			if lines.any?{|line| line =~ /on/}
				lines[prepend_line_index] = "#{prepend_line.chomp}, Actions\n"
				
				puts "Updating #{path}.."
				File.open(path, "w") do |file|
					file.write lines.join
				end
			end
		end
	end
end
```

### View Update 1.9.x to 2.x

Dynamic tags in 2.x require namespaces. This affects all `.xnode` files, in particular the following 3 cases:

1. Rewrite `<(/?)(NAME)(\W)` to `<$1content:$2$3` where NAME is a tag which would expand using a `_NAME.xnode` file.
2. Rewrite `<content/>` to `<utopia:content/>`. This affects `<node>`, `<deferred>`, `<environment>` tags.
3. Rewrite `partial 'NAME'` to be `partial 'content:NAME'`.

## Server Update

The utopia server git hooks are updated occasionally to improve the deployment process or to handle changes in the underlying process.

You can run the update process on the server to bring the git hooks up to the latest version.

```bash
$ cd /srv/http/website
$ utopia server update
```

You should keep your client and server deployment hooks in sync.
