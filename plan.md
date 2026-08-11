# Request Path Work

The current work should be split into the following focused pull requests.

## 1. Split redirection middleware into separate files.

Move each existing redirection middleware class into its own file without changing public constants, middleware ordering, request handling, or response behavior.

This change is structural and can be merged independently.

## 2. Use protocol URL paths in Utopia paths.

Upgrade to `protocol-url` v0.11 and allow `Utopia::Path` to consume `Protocol::URL::Path` instances without losing encoded component boundaries. Correct URL path decoding so literal `+` characters remain literal.

This change can be merged independently of request normalization.

## 3. Normalize structured request URLs at the application boundary.

Expose the request URL as a structured `Protocol::URL` value, normalize untrusted external paths during `Utopia::Request` construction, reject malformed or ambiguous paths as bad requests, and remove the `path_info` interface. Migrate the request consumers required to keep the application functional.

Before implementation, decide whether `request_path` stores the normalized original application path or the raw external path. Also decide whether an explicitly empty query delimiter, such as `/?`, must survive URL serialization and derived requests.

This change depends on topics 1 and 2.

## 4. Preserve URL boundaries in static file lookup.

Use `Protocol::URL::Path#local_path` when resolving static files so an encoded separator cannot become a filesystem separator. Simplify `Utopia::Static::LocalFile` around the resolved path and add boundary tests.

This change depends on topic 3.

## 5. Preserve URL boundaries in controller lookup.

Use component-aware controller cache keys and resolve controller paths through `Protocol::URL::Path#local_path`. Add tests proving encoded separators cannot address nested controllers or poison the controller cache.

This change depends on topic 3.

## 6. Preserve URL boundaries in content lookup.

Use component-aware content cache keys and resolve content paths through `Protocol::URL::Path#local_path`. Add tests proving encoded separators cannot address nested content.

This change depends on topic 3.

## 7. Bypass client redirects for internal error documents.

Place error-document handling inside client redirection middleware so internal error-document requests bypass client-visible redirects. Document the middleware ordering and test the response lifecycle.

This change depends on topics 1 and 3.
