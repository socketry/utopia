# Localization

The localization middleware uses the `Accept-Language` header to guess the preferred locale out of the given options. If a request path maps to a resource, that resource is returned. Otherwise, a localized request is made.

```ruby
use Utopia::Localization,
	:default_locale => 'en',
	:locales => ['en', 'de', 'ja', 'zh'],
	:nonlocalized => ['/_static/', '/_cache/']
```

Somewhere further down the chain, you can localize a resource:

```ruby
localization = Utopia::Localization[request]
show_welcome(localization.current_locale)
```
