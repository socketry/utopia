# Controller::Actions

Actions let you match path patterns in your controller and execute code. In your `controller.rb` simply add:

	prepend Actions

If you are adding multiple things, like rewriting, they should come earlier in the chain, e.g:

	prepend Rewrite, Actions

A simple CRUD controller might look like:

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
	
## Path Matching

Path matching works from right to left, and '**' is a greedy operator. Controllers are invoked with a path relative to the controller's `URI_PATH`, so all lookups are relative to the controller.

<dl>
	<dt><code>"*"</code></dt>
	<dd>Match a single path element</dd>
	<dt><code>"**"</code></dt>
	<dd>Match all remaining path elements</dd>
	<dt><code>String</code></dt>
	<dd>Match a named path component</dd>
	<dt><code>Symbol</code></dt>
	<dd>Equivalent to <code>["**", symbol.to_s]</code></dd>
</dl>

## Otherwise Matching

If no action was matched, it is sometimes useful to perform some specific behaviour. You can specify this by using the otherwise handler:

	otherwise do |request, path|
		fail! :teapot
	end

If you are doing this to perform some kind of rewriting, it may be preferable to use the [Rewrite](rewrite/) controller layer.
