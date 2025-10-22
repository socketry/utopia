# Releases

## Unreleased

  - Add agent context.
  - Better simplification of relative paths, e.g. `../../foo` is not modified to `foo`.
  - Move top level classes into `class Middleware` in their respective namespaces.
  - Move `Utopia::Responder` into `Utopia::Controller` layer.

## v2.30.1

  - Minor compatibility fixes.

## v2.27.0

  - Improved error logging using `Console` gem.
  - Only install `npm ls --production` dependencies into `public/_components`.
