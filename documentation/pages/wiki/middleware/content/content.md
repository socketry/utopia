# Content
A tag based content generation system which integrates nicely with HTML5. Supports structures which separate generic page templates from dynamically generated content in an easy and consistent way.

```ruby
use Utopia::Content,
	cache_templates: (RACK_ENV == :production),
	tags: {
		'deferred' => Utopia::Tags::Deferred,
		'override' => Utopia::Tags::Override,
		'node' => Utopia::Tags::Node,
		'environment' => Utopia::Tags::Environment.for(RACK_ENV)
	}
```

A basic template `create.xnode` looks something like:

```trenni
<page>
	<heading>Create User</heading>
	<form action="#">
		<input name="name" />
		<input type="submit" />
	</form>
</page>
```

This template would typically be designed with supporting `_page.xnode` and `_heading.xnode` in the same directory or, more typically, somewhere further up the directory hierarchy.
