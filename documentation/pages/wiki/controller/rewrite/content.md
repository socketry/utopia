# Controller::Rewrite

The `Controller::Rewrite` layer can match and rewrite requests before they processed. This allows you to handle URLs like `/post/15/view` or `/blog/123-pictures-of-my-cat` easily. The basic rewrite operation is to extract some part of the path and optionally executes a block. That means that the path is modified before being passed on to the next layer in the controller, and controller instance variables may be set.

## Regular Expressions

In your `controller.rb`:

	prepend Rewrite, Actions
	
	rewrite.extract_prefix permalink: /(?<id>\d+)-(?<title>.*)/ do |request, path, match|
		# The rewrite matched, but there was no valid post, so we fail:
		fail! unless @post = Post.find(@permalink[:id])
		
		# If the path matched, but there was no suffix, we make it default to the post action:
		if match.post_match.empty?
			match.post_match.components << "post"
		end
	end
	
	on 'post' do
		# You can do further processing here.
		fail! unless @post.published?
		
		@comments = @post.comments.first(5)
	end

	on 'edit' do
		# You can do further processing here.
		fail! unless @current_user&.editor?
	end

In your `post.xnode`, as an example:

	<page>
		<heading>Post #{attributes[:permalink][:id]} about #{attributes[:permalink][:title]}</heading>
		
		<p>#{attributes[:post].content}</p>
	</page>

Keep in mind, that URLs like `/123-pictures-of-my-cat/edit` will work as expected, and hit the `edit` action of the controller.

## Restful Resources

Similar to the above, if we were solely interested in IDs, we could do the following:

	prepend Rewrite, Actions
	
	rewrite.extract_prefix post_id: Integer do |request, path, match|
		# The rewrite matched, but there was no valid post, so we fail:
		fail! unless @post = Post.find(@post_id)
		
		# If the path matched, but there was no suffix, we make it default to the post action:
		if match.post_match.empty?
			match.post_match.components << "post"
		end
	end

This will only match complete integers. Assuming this code is in `/blog/controller.rb`, it would match something like `/blog/123/view` and assign Integer("123") to `@post_id`.

### Matching.. other things

It's possible to match using `Integer`, `Float`, `String`, and you can provide your own class which will be instantiated. If it doesn't match, raise an exception and the rewrite rule will fail.

