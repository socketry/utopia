# What is `.xnode`?

Xnodes are the files on disk which are used as part of Utopia's content/view layer. Xnode templates are designed to maximise the ratio of content to markup. They improve separation of concerns and semantic organisation because repeated markup can be reused easily.

Here is a example of a blog post:

```xml
<content:entry title="My day as a fish">
	<p>It was not very exciting</p>
</content:entry>
```

The `Utopia::Content` middleware is built on top of the [Trenni](https://github.com/ioquatix/trenni) template language which uses two-phase evaluation.

## Phase 1: Evaluation

Trenni processes the view content by evaluation `#{expressions}` and `<?r statements ?>`. This generates an output buffer. The output buffer should contain valid markup (i.e. balanced tags, no invalid characters).

## Phase 2: Markup

Once the template is evaluated to text, it is parsed again into an event stream which is used to generate the final output. The event stream contains things like "open tag", "attribute", "close tag", and so on, and these are fed into the `Utopia::Content` middleware which generates the actual content. Tags without namespaces are output verbatim, while tags with namespaces invoke the tag lookup machinery. This uses the tag name to invoke further behaviour, e.g. inserting more content. Here is a simple example of a basic page:

```xml
<content:page>
	<content:heading>Welcome to my page</content:heading>

	<p>This page is so awesome</p>
</content:page>
```

In order to render this, you will need two additional files, `_page.xnode` and `_heading.xnode`. As a short example, `_heading.xnode` might look like this:

```xml
<h1><utopia:content/></h1>
```

When the parser encounters `<content:heading>...` in the main page, it would evaluate the above template. `<utopia:content/>` is a special tag that evaluates to the content that the parent tag provided, so in this case: `"Welcome to my page"`.  Thus, the final output is `<h1>Welcome to my page</h1>`.
