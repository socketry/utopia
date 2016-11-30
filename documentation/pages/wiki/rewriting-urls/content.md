# Rewriting URLs

The `Controller::Rewrite` layer can match and rewrite requests before they processed. This allows you to have URLs like `/post/15/view` or `/blog/123-pictures-of-my-cat`. The basic rewrite operation is to extract some part of the path prefix. That means that the path is modified before being passed on to the next layer in the controller.

## Permalink Example

In your `controller.rb`:

	prepend Actions, Rewrite
	
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