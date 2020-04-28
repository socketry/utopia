# Controller::Actions

Actions let you match path patterns in your controller and execute code. In your `controller.rb` simply add:

```ruby
prepend Actions
```

If you are adding multiple things, like rewriting, they should come earlier in the chain, e.g:

```ruby
prepend Rewrite, Actions
```

A simple CRUD controller might look like:

```ruby
prepend Actions

on 'index' do
	@users = User.all
end

on 'new' do |request|
	@user = User.new
	
	if request.post?
		@user.update_attributes(request.params['user'])
		
		redirect! "index"
	end
end

on 'edit' do |request|
	@user = User.find(request.params['id'])
	
	if request.post?
		@user.update_attributes(request.params['user'])
		
		redirect! "index"
	end
end

on 'delete' do |request|
	User.find(request.params['id']).destroy
	
	redirect! "index"
end
```
	
## Path Matching

Path matching works from right to left, and `'**'` is a greedy operator. Controllers are invoked with a path relative to the controller's `URI_PATH`, so all lookups are relative to the controller.

<dl>
	<dt><code class="language-ruby">"*"</code></dt>
	<dd>Match a single path element</dd>
	<dt><code class="language-ruby">"**"</code></dt>
	<dd>Match all remaining path elements</dd>
	<dt><code class="language-ruby">String</code></dt>
	<dd>Match a named path component, e.g. <code class="language-ruby">"edit"</code>.</dd>
	<dt><code class="language-ruby">Symbol</code></dt>
	<dd>Equivalent to <code class="language-ruby">["**", symbol.to_s]</code>, e.g. <code class="language-ruby">:logout</code>.</dd>
</dl>

## Otherwise Matching

If no action was matched, it is sometimes useful to perform some specific behaviour. You can specify this by using the otherwise handler:

```ruby
otherwise do |request, path|
	fail! :teapot
end
```

If you are doing this to perform some kind of rewriting, it may be preferable to use the [Rewrite](../rewrite/) controller layer.