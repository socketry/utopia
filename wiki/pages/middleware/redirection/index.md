# Redirection

A set of flexible URI rewriting middleware which includes support for string mappings, regular expressions and status codes (e.g. 404 errors).

```ruby
# String (fast hash lookup) rewriting:
use Utopia::Redirection::Rewrite,
	'/' => '/welcome/index'

# Redirect directories (e.g. /) to an index file (e.g. /index):
use Utopia::Redirection::DirectoryIndex,
	index: 'index.html'

# Redirect (error) status codes to actual pages:
use Utopia::Redirection::Errors,
	404 => '/errors/file-not-found'
```
