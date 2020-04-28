# Utopia

Utopia is a content management system built on top of Ruby. It makes creating, deploying and updating content-driven websites easy.

## Introduction Guide

Reading these pages in order will give you an overview of the design of Utopia, how to set it up for local development and how to deploy it.

- [Development Environment Setup](development-environment-setup/)
- [Server Setup](server-setup/)
- [Your First Page](your-first-page/)
  - [What is `.xnode`?](faq/what-is-xnode/)
- [Installing JavaScript Libraries](javascript/)
- [Website Tests](testing/)
- [Updating Your Site](updating-utopia/)

## Middleware

The following are Rack Middleware which provide the core of Utopia.

- [Static](middleware/static/) — Serve static files efficiently.
- [Redirection](middleware/redirection/) — Redirect URL patterns and status codes.
- [Localization](middleware/localization/) — Non-intrusive localization of resources.
- [Controller](middleware/controller/) — Flexible nested controllers with efficient behaviour. 
  - [Controller Actions](middleware/controller/actions/) — Invoke named actions.
  - [Controller Rewrite](middleware/controller/rewrite/) — Pattern match requests.
- [Content](middleware/content/) — XML-style template engine with dynamic markup.
- [Session](middleware/session/) — Session storage using encrypted client-side cookies.

## Examples

Here are some open-source sites built on Utopia.

- [www.codeotaku.com](http://www.codeotaku.com) ([source](https://github.com/ioquatix/www.codeotaku.com)) — Personal website, blog.
- Financier ([source](https://github.com/ioquatix/financier)) — Small business management platform, invoicing.
