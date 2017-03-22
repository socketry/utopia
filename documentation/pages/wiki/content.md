# Utopia Documentation Wiki

This wiki includes documentation and examples showing how to use Utopia. You can also browse the [code documentation](/code/index.html) for more detail.

## Introduction Guide

Reading these pages in order will give you an overview of the design of Utopia, how to set it up for local development and how to deploy it.

- [Development Environment Setup](development-environment-setup/)
- [Server Setup](server-setup/)
- [Your First Page](your-first-page/)
- [Installing JavaScript Libraries](bower-integration/)
- [Website Tests](testing/)
- [Updating Your Site](updating-utopia/)

## Middleware

- [Static](middleware/static/) — Serve static files efficiently.
- [Redirection](middleware/redirection/) — Redirect URL patterns and status codes.
- [Localization](middleware/localization/) — Non-intrusive localization of resources.
- [Controller](middleware/controller/) — Flexible nested controllers with efficient behaviour. 
  - [Controller Actions](middleware/controller/actions/) — Invoke named actions.
  - [Controller Rewrite](middleware/controller/rewrite/) — Pattern match requests.
- [Content](middleware/content/) — XML-style template engine with dynamic markup.
- [Session](middleware/session/) — Session storage using encrypted client-side cookies.